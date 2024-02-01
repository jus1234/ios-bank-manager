import Foundation

final class Bank {
    private let customerCountRange: ClosedRange<Int> = 10...30
    private var customerCount: Int
    private var depositCustomerQueue: LinkedListQueue<Customer>
    private var loanCustomerQueue: LinkedListQueue<Customer>
    private var depositManagerQueue: LinkedListQueue<BankManager>
    private var loanManagerQueue: LinkedListQueue<BankManager>
    private var isDepositManagerWorking: Bool
    private var isLoanManagerWorking: Bool
    private var isbankWorking: Bool {
        return isDepositManagerWorking || isLoanManagerWorking
    }
    
    init() {
        self.customerCount = 0
        self.depositCustomerQueue = LinkedListQueue<Customer>()
        self.loanCustomerQueue = LinkedListQueue<Customer>()
        self.depositManagerQueue = LinkedListQueue<BankManager>()
        self.loanManagerQueue = LinkedListQueue<BankManager>()
        self.isDepositManagerWorking = true
        self.isLoanManagerWorking = true
    }
}

extension Bank {
    func process() {
        Message.menu.printMessage()
        Message.input.printMessage()
        
        guard let selectedMenu = selectMenu() else {
            Message.wrongInput.printMessage()
            process()
            return
        }
        
        if selectedMenu == Menu.exit.value {
            return
        }
        
        makeBankManagerQueue(depositManagerCount: 2, loanManagerCount: 1)
        makeCustomerQueue()
        openBanck()
    }
    
    private func selectMenu() -> Int? {
        guard let input = readLine(),
              let selectedMenu = Int(input),
              (Menu.open.value...Menu.exit.value) ~= selectedMenu else {
            return nil
        }
        return selectedMenu
    }
    
    private func makeBankManagerQueue(depositManagerCount: Int, loanManagerCount: Int) {
        (1...depositManagerCount).forEach { _ in
            depositManagerQueue.enqueue(element: BankManager())
        }
        (1...loanManagerCount).forEach { _ in
            loanManagerQueue.enqueue(element: BankManager())
        }
    }
    
    private func makeCustomerQueue() {
        (1...Int.random(in: customerCountRange)).forEach {
            let task: Task = Int.random(in: 1...2) == 1 ? .deposit : .loan
            let customerQueue = task == .deposit ? depositCustomerQueue : loanCustomerQueue
            customerQueue.enqueue(element: Customer(number: $0, task: task))
            customerCount += 1
        }
        isDepositManagerWorking = depositCustomerQueue.isEmpty ? false : true
        isLoanManagerWorking = loanCustomerQueue.isEmpty ? false : true
    }
    
    private func openBanck() {
        let openTime: Date = Date()
        while isbankWorking {
            handleQueues(task: .deposit)
            handleQueues(task: .loan)
        }
        closeBank(openTime)
    }
    
    private func handleQueues(task: Task) {
        let managerQueue: LinkedListQueue<BankManager> = task == .deposit ? depositManagerQueue : loanManagerQueue
        let customerQueue: LinkedListQueue<Customer> = task == .deposit ? depositCustomerQueue : loanCustomerQueue
        if let manager: BankManager = managerQueue.dequeue(),
           let customer: Customer = customerQueue.dequeue() {
            assignTask(to: manager, with: customer)
        }
    }
    
    private func assignTask(to bankManager: BankManager, with customer: Customer) {
        let isLastCustomer: Bool = customer.task == .deposit ? depositCustomerQueue.isEmpty : loanCustomerQueue.isEmpty
        DispatchQueue.global().async {
            bankManager.deal(with: customer,
                             isLastCustomer: isLastCustomer,
                             completionHandler: { [weak self] (manager, task, isLastCustomer) in
                let managerQueue = task == .deposit ? self?.depositManagerQueue : self?.loanManagerQueue
                managerQueue?.enqueue(element: manager)
                if isLastCustomer {
                    self?.finishManaging(task)
                }
            })
        }
    }
    
    private func finishManaging(_ task: Task) {
        if task == .deposit {
            isDepositManagerWorking = false
            return
        }
        isLoanManagerWorking = false
    }
    
    private func closeBank(_ openTime: Date) {
        Message.close(customerCount: customerCount, time: Date().timeIntervalSince(openTime)).printMessage()
        customerCount = 0
        process()
    }
    
}
