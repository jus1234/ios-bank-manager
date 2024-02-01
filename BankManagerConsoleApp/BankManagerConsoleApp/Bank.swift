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
            handleDepositQueues()
            handleLoanQueues()
        }
        closeBank(openTime)
    }
    
    private func handleDepositQueues() {
        if let depositManager: BankManager = depositManagerQueue.dequeue(),
           let depositCustomer: Customer = depositCustomerQueue.dequeue() {
            assignDepositTask(to: depositManager, with: depositCustomer)
        }
    }
    
    private func handleLoanQueues() {
        if let loanManager: BankManager = loanManagerQueue.dequeue(),
           let loanCustomer: Customer = loanCustomerQueue.dequeue() {
            DispatchQueue.global().async {
                loanManager.deal(with: loanCustomer,
                                 isLastCustomer: self.loanCustomerQueue.isEmpty,
                                 completionHandler: { [unowned self] (manager, isLastLoanCustomer) in
                    self.loanManagerQueue.enqueue(element: manager)
                    if isLastLoanCustomer {
                        self.finishLoanManaging()
                    }
                })
            }
        }
    }
    
    private func assignDepositTask(to bankManager: BankManager, with customer: Customer) {
        DispatchQueue.global().async {
            bankManager.deal(with: customer,
                                isLastCustomer: self.depositCustomerQueue.isEmpty,
                                completionHandler: { [weak self] (manager, isLastDepositCustomer) in
                self?.depositManagerQueue.enqueue(element: manager)
                if isLastDepositCustomer {
                    self?.finishDepositManaging()
                }
            })
        }
    }
    
    
    
    private func closeBank(_ openTime: Date) {
        Message.close(customerCount: customerCount, time: Date().timeIntervalSince(openTime)).printMessage()
        customerCount = 0
        process()
    }
    
    private func finishDepositManaging() {
        isDepositManagerWorking = false
    }
    
    private func finishLoanManaging() {
        isLoanManagerWorking = false
    }
    
}
