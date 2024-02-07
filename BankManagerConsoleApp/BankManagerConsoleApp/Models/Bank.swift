import Foundation

final class Bank {
    private let customerCountRange: ClosedRange<Int> = 10...15
    private var totalCustomer: Int
    private var depositCustomerQueue: LinkedListQueue<Customer>
    private var loanCustomerQueue: LinkedListQueue<Customer>
    private var depositManagerQueue: DispatchSemaphore
    private var loanManagerQueue: DispatchSemaphore
    
    init() {
        self.totalCustomer = 0
        self.depositCustomerQueue = LinkedListQueue<Customer>()
        self.loanCustomerQueue = LinkedListQueue<Customer>()
        self.depositManagerQueue = DispatchSemaphore(value: 2)
        self.loanManagerQueue = DispatchSemaphore(value: 1)
    }
}


extension Bank {
    
    func process() {
        Message.menu.printMessage()
        Message.input.printMessage()
        let selectedMenu = validate()
        switch selectedMenu {
        case .wrongInput:
            Message.wrongInput.printMessage()
            process()
        case .open:
            makeCustomerQueue()
            openBank()
            closeBank(Date())
        case .exit:
            return
        }
    }
    
    private func validate() -> Menu {
        
        guard let userInput = readLine() else {
            return .wrongInput
        }
        return Menu(input: userInput)
    }
    
    private func makeCustomerQueue() {
        let totalCustomer = Int.random(in: customerCountRange) // 총 고객 수 결정
        self.totalCustomer = totalCustomer // 실제 고객 수를 업데이트
        print("\(totalCustomer)")

        for number in 1...totalCustomer {
            let task: Task = Bool.random() ? .deposit : .loan
            let customer = Customer(number: number, task: task)
            if task == .deposit {
                depositCustomerQueue.enqueue(customer)
            } else {
                loanCustomerQueue.enqueue(customer)
            }
        }
    }
    
        private func openBank() {
            let openTime: Date = Date()
            let dispatchGroup = DispatchGroup()
            print("Opening bank")
            
            DispatchQueue.global().async { [self] in
                processQueue(loanCustomerQueue, semaphore: loanManagerQueue, dispatchGroup: dispatchGroup, queueType: "loan")
                processQueue(depositCustomerQueue, semaphore: depositManagerQueue, dispatchGroup: dispatchGroup, queueType: "deposit")
            }
            
         
            dispatchGroup.notify(queue: .global()) {
                print("notiy")
                self.closeBank(openTime)
            }
        }
        
    private func processQueue(_ queue: LinkedListQueue<Customer>, semaphore: DispatchSemaphore, dispatchGroup: DispatchGroup,queueType: String) {
        while let customer = queue.dequeue() {
            print("\(customer): -- ")
            dispatchGroup.enter()
            print("\(queueType) Queue - Customer \(customer.number) dequeue started")

            semaphore.wait()
            DispatchQueue.global().async {
                self.processCustomer(customer) {
                    print("\(queueType) Queue - Customer \(customer.number) processing completed")
                    
                    semaphore.signal()
                    dispatchGroup.leave()
                }
            }
        }
    }

        
        private func processCustomer(_ customer: Customer, completion: @escaping () -> Void) {
            let manager = BankManager()
            manager.deal(with: customer, isLastCustomer: totalCustomer == 0) { (manager, task, isLastCustomer) in
                completion()
            }
        }
        
        private func closeBank(_ openTime: Date) {
           print("closeBank호출")
            Message.close(customerCount: totalCustomer, time: Date().timeIntervalSince(openTime)).printMessage()
            totalCustomer = 0
            process()
        }
    }
    
