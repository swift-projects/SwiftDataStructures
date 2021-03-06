//
//  Stack.swift
//  SwiftDataStructures
//
//  Created by bryn austin bellomy on 2014 Dec 17.
//  Copyright (c) 2014 bryn austin bellomy. All rights reserved.
//

public struct StackIndex<T> : BidirectionalIndexType, Comparable, IntegerLiteralConvertible
{
    public typealias RawIndex = Stack<T>.UnderlyingCollection.Index
    private typealias UnderlyingIndex = Stack<T>.UnderlyingCollection.Index

    private let value : RawIndex
    public init(_ v: RawIndex) {
        value = v
    }

//    public func underlyingIndexGivenEndIndex(endIndex:Stack<T>.UnderlyingCollection.Index) -> Stack<T>.UnderlyingCollection.Index {
//        return endIndex.predecessor() - value
//    }

    func underlyingIndex(underlying:Stack<T>.UnderlyingCollection) -> Stack<T>.UnderlyingCollection.Index {
        return underlying.endIndex.predecessor() - value
    }
    
    public init(integerLiteral value:Int) {
        self.init(value)
    }

    public func successor() -> StackIndex<T> {
        return StackIndex<T>(value.successor())
    }

    public func predecessor() -> StackIndex<T> {
        return StackIndex<T>(value.predecessor())
    }
}

public func == <T>(lhs: StackIndex<T>, rhs: StackIndex<T>) -> Bool {
    return lhs.value == rhs.value
}

public func < <T>(lhs:StackIndex<T>, rhs: StackIndex<T>) -> Bool {
    return lhs.value < rhs.value
}


//
// MARK: - struct Stack<T> -
//

public struct Stack<T>
{

    public   typealias Element = T
    internal typealias UnderlyingCollection = LinkedList<Element>

    private var elements = UnderlyingCollection()

    public var top     : Element?       { return elements.last?.item }
    public var bottom  : Element?       { return elements.first?.item }
    public var count   : Index.Distance { return elements.count }
    public var isEmpty : Bool           { return count == 0 }

    public init() {
    }

    /**
        Element order is [top, ..., bottom], as if one were to iterate through the sequence in reverse, calling `stack.push(element)` on each element.
     */
    public init<S : SequenceType where S.Generator.Element == Element>(_ elements:S) {
        appendContentsOf(elements)
    }

    /**
        Adds an element to the top of the stack.
    
        - parameter elem: The element to add.
    */
    public mutating func push(elem: Element) {
        let newElement = UnderlyingCollection.NodeType(elem)
        elements.append(newElement)
    }

    /**
        Removes the top element from the stack and returns it.
    
        - returns: The removed element or `nil` if the stack is empty.
     */
    public mutating func pop() -> Element? {
        return (count > 0) ? removeTop() : nil
    }


    /**
        Returns the element at the specified index, or nil if the index was out of range.
     */
    public func at(index i:Int) -> Element? {
        let underlyingIndex = Index(i).underlyingIndex(elements)
        return elements.at(underlyingIndex)?.item
    }


    /**
        Returns the index of the first element for which `predicate` returns true.
     */
    public func find(predicate: (Element) -> Bool) -> Index? {
        for (i, elem) in self.enumerate() {
            if predicate(elem) == true {
                return Index(i)
            }
        }
        return nil
    }


    /**
        Inserts the provided element `n` positions from the top of the stack.  The index must be >= startIndex and <= endIndex or a precondition will fail.  Insert can therefore be used to append and prepend elements to the list (and, in fact, `append` and `prepend` simply call this function).
    */
    public mutating func insert(newElement:Element, atIndex i:Index.RawIndex) {
        insert(newElement, atIndex:Index(i))
    }

    public mutating func insert(newElement:Element, atIndex index:Index) {
        precondition(index >= startIndex && index <= endIndex)

        let elem = UnderlyingCollection.NodeType(newElement)
        let underlyingIndex = index.underlyingIndex(elements)
        elements.insert(elem, atIndex:underlyingIndex)
    }


    /**
        Removes the element `n` positions from the top of the stack and returns it.  `index` must be a valid index or a precondition assertion will fail.

        - parameter index: The index of the element to remove.
        - returns: The removed element.
     */
    public mutating func removeAtIndex(index:Index) -> Element {
        precondition(index >= startIndex && index <= endIndex.predecessor(), "index (\(index)) is out of range [startIndex = \(startIndex), endIndex = \(endIndex), count = \(count)].")

        let underlyingIndex = index.underlyingIndex(elements)
        return elements.removeAtIndex(underlyingIndex).item
    }

    public mutating func removeAtIndex(index:Index.RawIndex) -> Element {
        return removeAtIndex(Index(index))
    }

    /**
        This function is equivalent to `pop()`, except that it will fail if the stack is empty.
    
        - returns: The removed element.
     */
    public mutating func removeTop() -> Element {
        precondition(count > 0, "Cannot removeTop() from an empty Stack.")
        return elements.removeLast().item
    }
}



//
// MARK: - Stack : SequenceType
//

extension Stack : SequenceType
{
    public typealias Generator = AnyGenerator<Element>
    public func generate() -> Generator {
        var generator = Array(elements.reverse()).generate()
        return anyGenerator {
            return generator.next()?.item
        }
    }
}



//
// MARK: - Stack : MutableCollectionType
//

extension Stack : MutableCollectionType
{
    public typealias Index = StackIndex<T>
    public var startIndex : Index { return StackIndex(elements.startIndex) }
    public var endIndex   : Index { return StackIndex(elements.endIndex) }

    /**
        Subscript `n` corresponds to the element that is `n` positions from the top of the stack.  Subscript 0 always corresponds to the top element.
     */
    public subscript(index:Index) -> Element {
        get {
            let underlyingIndex = index.underlyingIndex(elements)
            return elements[underlyingIndex].item
        }
        set {
            let underlyingIndex = index.underlyingIndex(elements)
            let newNode = UnderlyingCollection.NodeType(newValue)
            elements[underlyingIndex] = newNode
        }
    }

    public subscript(index:Index.RawIndex) -> Element {
        get { return self[ Index(index) ] }
        set { self[ Index(index) ] = newValue }
    }
}



//
// MARK: - Stack : ExtensibleCollectionType
//

extension Stack : RangeReplaceableCollectionType
{    
    public mutating func reserveCapacity(n: Index.Distance) {
        elements.reserveCapacity(n)
    }

    /**
        Appends an element to the bottom of the stack.  Included for `ExtensibleCollectionType` conformance.
     */
    public mutating func append(newElement:Element) {
        elements.prepend(LinkedListNode(newElement))
    }


    /**
        Element order is [top, ..., bottom], as if one were to iterate through the sequence in reverse, calling `stack.append(element)` on each element.
     */
    public mutating func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(sequence: S) {
        for elem in sequence {
            append(elem)
        }
    }
    
    public mutating func replaceRange<C : CollectionType where C.Generator.Element == Generator.Element>(subRange: Range<Index>, with newElements: C) {
        let nodes = newElements.map { UnderlyingCollection.NodeType($0) }
        
        let start = UnderlyingCollection.Index(subRange.startIndex.underlyingIndex(elements))
        let end   = UnderlyingCollection.Index(subRange.endIndex.underlyingIndex(elements))
        elements.replaceRange(Range(start: start, end: end), with: nodes)
    }
}



//
// MARK: - Stack : ArrayLiteralConvertible
//

//extension Stack : ArrayLiteralConvertible
//{
//    /**
//        Element order is [top, ..., bottom], as if one were to iterate through the sequence in reverse, calling `stack.push(element)` on each element.
//     */
//    public init(arrayLiteral elements: Element...) {
//        appendContentsOf(elements)
//    }
//}



//
// MARK: - Stack: Printable, DebugPrintable
//

extension Stack: CustomStringConvertible, CustomDebugStringConvertible
{
    public var description: String {
        let arr = Array(self)
        return arr.description
    }

    public var debugDescription: String { return description }
}




