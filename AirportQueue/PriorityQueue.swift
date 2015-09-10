//
//  PriorityQueue.swift
//  AirportQueue
//
//  Created by Benjamin Johnson on 10/09/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

public class PriorityQueue<T> {
    
    final var heap: [T]
    private let compare: (T, T) -> Bool
    
    public init(_ compare: (T, T) -> Bool) {
        heap = []
        self.compare = compare
    }
    
    public func push(newElement: T) {
        heap.append(newElement)
        siftUp(heap.endIndex - 1)
    }
    
    public func pop() -> T? {
        if heap.count == 0  {
            return nil
        }
        else if 0 != heap.endIndex - 1 {
            swap(&heap[0], &heap[heap.endIndex - 1])
        }
        
        let pop = heap.removeLast()
        siftDown(0)
        return pop
    }
    
    private func siftDown(index: Int) -> Bool {
        let left = index * 2 + 1
        let right = index * 2 + 2
        var smallest = index
        
        if left < heap.count && compare(heap[left], heap[smallest]) {
            smallest = left
        }
        if right < heap.count && compare(heap[right], heap[smallest]) {
            smallest = right
        }
        if smallest != index {
            swap(&heap[index], &heap[smallest])
            siftDown(smallest)
            return true
        }
        return false
    }
    
    private func siftUp(index: Int) -> Bool {
        if index == 0 {
            return false
        }
        let parent = (index - 1) >> 1
        if compare(heap[index], heap[parent]) {
            swap(&heap[index], &heap[parent])
            siftUp(parent)
            return true
        }
        return false
    }
}

extension PriorityQueue {
    public var count: Int {
        return heap.count
    }
    
    public var isEmpty: Bool {
        return heap.isEmpty
    }
    
    public func update<T2 where T2: Equatable>(element: T2) -> T? {
        assert(element is T)  // How to enforce this with type constraints?
        for (index, item) in heap.enumerate() {
            if (item as! T2) == element {
                heap[index] = element as! T
                if siftDown(index) || siftUp(index) {
                    return item
                }
            }
        }
        return nil
    }
    
    public func remove<T2 where T2: Equatable>(element: T2) -> T? {
        assert(element is T)  // How to enforce this with type constraints?
        for (index, item) in heap.enumerate() {
            if (item as! T2) == element {
                swap(&heap[index], &heap[heap.endIndex - 1])
                heap.removeLast()
                siftDown(index)
                return item
            }
        }
        return nil
    }
    
}

extension PriorityQueue: GeneratorType {
    public typealias Element = T
    public func next() -> Element? {
        return pop()
    }
}

extension PriorityQueue: SequenceType {
    public typealias Generator = PriorityQueue
    public func generate() -> Generator {
        return self
    }
}