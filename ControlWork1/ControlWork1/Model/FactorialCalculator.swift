
//
//  FactorialCalculator.swift
//  ControlWork1
//
//  Created by Дмитрий Леонтьев on 21.11.2024.
//

import Foundation

class FactorialCalculator {
    func calculateFactorial(of number: Int) async -> Int {
        await withTaskCancellationHandler {
            return await computeFactorial(of: number)
        } onCancel: {
            print("Вычисления отменены.")
        }
    }
    private func computeFactorial(of number: Int) -> Int {
        var result = 1
        for i in 1...number {
            if Task.isCancelled {
                print("Задача отменена.")
                return -1
            }
            result *= i
        }
        return result
    }

    func calculateFactorials(upTo number: Int, progressUpdate: @escaping (Float) -> Void) async -> [Int] {
        var results: [Int] = []
        for i in 1...number {
            if Task.isCancelled {
                print("Задача отменена.")
                return []
            }
            let factorial = await computeFactorial(of: i)
            results.append(factorial)
            await MainActor.run {
                progressUpdate(Float(i) / Float(number))
            }
        }
        return results
    }
}
