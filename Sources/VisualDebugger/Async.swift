import Foundation

func transferToMain(_ work: @escaping () -> ()) {
    DispatchQueue.main.async(execute: work)
}
