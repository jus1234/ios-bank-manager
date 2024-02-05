import Foundation

final class Bank {
    private let customerCountRange: ClosedRange<Int> = 10...30
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
        let customerCount = Int.random(in: customerCountRange)
        for number in 1...customerCount {
            let task: Task = Bool.random() ? .deposit : .loan
            let customer = Customer(number: number, task: task)
            let customerQueue = task == .deposit ? depositCustomerQueue : loanCustomerQueue
            customerQueue.enqueue(customer)
            totalCustomer += 1
        }
    }
    
    private func openBank() {
          let openTime: Date = Date()
          let dispatchGroup = DispatchGroup()
        processQueue(depositCustomerQueue, semaphore: depositManagerQueue, dispatchGroup: dispatchGroup)
        processQueue(loanCustomerQueue, semaphore: loanManagerQueue, dispatchGroup: dispatchGroup)
        dispatchGroup.notify(queue: .global()) {
              self.closeBank(openTime)
          }
      }
      
    private func processQueue(_ queue: LinkedListQueue<Customer>, semaphore: DispatchSemaphore, dispatchGroup: DispatchGroup) {
        while let customer = queue.dequeue() {
            dispatchGroup.enter()
            semaphore.wait()
            DispatchQueue.global().async {
                self.processCustomer(customer) {
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
        Message.close(customerCount: totalCustomer, time: Date().timeIntervalSince(openTime)).printMessage()
        totalCustomer = 0
        process()
    }
}

