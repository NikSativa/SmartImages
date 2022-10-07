import Foundation
import Nimble
import NSpry
import NSpry_Nimble
import Quick

@testable import NCallback
@testable import NCallbackTestHelpers
@testable import NImageDownloader
@testable import NImageDownloaderTestHelpers

final class ImageDownloadOperationSpec: QuickSpec {
    private enum Result: Equatable {
        case absent
        case received(Image?)
    }

    override func spec() {
        describe("ImageDownloadOperation") {
            var subject: ImageDownloadOperation!
            var requestGenerator: Impl.ImageDownloadOperation.Generator!
            var requestGeneratorCounter: Int = 0
            var request: FakeCallback<Image?>!
            var completionCallback: FakeCallback<Image?>!
            var url: URL!
            var timestamp: TimeInterval!
            let lifecycleId: UInt64 = 1111

            beforeEach {
                request = .init()
                requestGenerator = {
                    requestGeneratorCounter += 1
                    return request
                }
                completionCallback = .init()
                url = .testMake()

                let date = Date()
                timestamp = date.timeIntervalSinceReferenceDate

                subject = Impl.ImageDownloadOperation(requestGenerator: requestGenerator,
                                                      completionCallback: completionCallback,
                                                      url: url,
                                                      date: date,
                                                      lifecycleId: lifecycleId)
            }

            afterEach {
                request.resetCallsAndStubs()
                completionCallback.resetCallsAndStubs()

                requestGeneratorCounter = 0
                subject = nil
            }

            it("should be in idle state") {
                expect(subject.state) == .idle
            }

            it("should save timestamp since reference date") {
                expect(subject.timestamp) == timestamp
            }

            it("should save url") {
                expect(subject.url) == url
            }

            describe("cancel") {
                beforeEach {
                    subject.cancel()
                }

                it("should set corresponding state") {
                    expect(subject.state) == .canceled
                }

                context("when canceling for the second time") {
                    it("should throw assert") {
                        expect({ subject.cancel() }).to(throwAssertion())
                    }
                }

                context("when starting already canceled operation") {
                    it("should throw assert") {
                        expect({ subject.start() }).to(throwAssertion())
                    }
                }
            }

            describe("start") {
                var operationCallback: Callback<Image?>!

                beforeEach {
                    operationCallback = subject.start()
                }

                it("should set create operation callback") {
                    expect(operationCallback).toNot(beNil())
                }

                it("should not generate request") {
                    expect(requestGeneratorCounter) == 0
                }

                context("when canceling before initiating operation") {
                    beforeEach {
                        subject.cancel()
                    }

                    it("should set corresponding state") {
                        expect(subject.state) == .canceled
                    }

                    context("when initiating operation") {
                        var called: Result = .absent

                        beforeEach {
                            operationCallback.onComplete { image in
                                called = .received(image)
                            }
                        }

                        it("should not called completion") {
                            expect(called) == .absent
                        }
                    }
                }

                context("when initiating operation") {
                    var called: Result = .absent

                    beforeEach {
                        request.stub(.beforeComplete).andReturn(request)
                        request.stub(.deferred).andReturn(request)
                        request.stub(.onComplete).andReturn()

                        operationCallback.onComplete { image in
                            called = .received(image)
                        }
                    }

                    it("should subscribe beforeComplete event") {
                        expect(request).to(haveReceived(.beforeComplete))
                    }

                    it("should start original request") {
                        expect(request).to(haveReceived(.onComplete, with: CallbackOption.oneOff(.weakness), Argument.anything))
                    }

                    it("should not called completion") {
                        expect(called) == .absent
                    }

                    it("should set corresponding state") {
                        expect(subject.state) == .running
                    }

                    it("should generate request") {
                        expect(requestGeneratorCounter) == 1
                    }

                    context("when received beforeComplete") {
                        let image: Image = .init()

                        beforeEach {
                            request.beforeComplete?(image)
                        }

                        it("should finish operation and remove request from memory") {
                            expect(subject.state) == .finished
                        }
                    }

                    context("when received onComplete") {
                        let image: Image = .init()

                        beforeEach {
                            request.beforeComplete?(image)
                        }

                        it("should finish operation and remove request from memory") {
                            expect(subject.state) == .finished
                        }
                    }
                }
            }
        }
    }
}
