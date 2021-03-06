//
//  NotesHelper.swift
//  Note_WeThree
//
//  Created by Chaitanya Sanoriya on 19/06/20.
//  Copyright © 2020 Chaitanya Sanoriya. All rights reserved.
//

import Foundation
import CoreData
import UIKit

enum CustomExceptions: Error
{
    case NoInstanceException
    case InavlidIndexException
    case InvalidCategoryException
}

/// Notes Helper class, handles all the Note Data Operations. Implements Singleton Design Pattern.
class NotesHelper
{
    private var mNotes: [Note]
    private var mCategories: [String]
    private var mCategoryNoteCount: [Int:Int]
    private static var mInstance: NotesHelper?
    
    /// Parameterised Constructor to load all the Categories and Notes at the startup time
    private init()
    {
        self.mNotes = []
        self.mCategories = []
        self.mCategoryNoteCount = [:]
    }
    
    /// This Function creates an instance of NotesHelper Class and returns it, implementing Singleton Design Pattern
    /// - Returns: Instance of NotesHelper
    internal static func getInstance() -> NotesHelper
    {
        if(mInstance == nil)
        {
            mInstance = NotesHelper()
        }
        return mInstance!
    }
    
    /// Function loads all the Categories in memory
    /// - Parameter context: It is NSManagedObjectContext to be able to access Database
    internal func loadAllCategories(context: NSManagedObjectContext)
    {
        mCategories = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Categories")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true)]
        var results: [NSManagedObject] = []
        do
        {
            results = try context.fetch(fetchRequest)
        }
        catch
        {
            print(error)
        }
        for result in results
        {
            mCategories.append( result.value(forKey: "category") as! String)
        }
        loadCategoryNoteCount(context: context)
    }
    
    /// Counts the Number of Notes grouped by Category
    /// - Parameter context: NSManagedObjectContext to be able to access Database
    private func loadCategoryNoteCount(context: NSManagedObjectContext)
    {
        mCategoryNoteCount = [:]
        for i in 0..<mCategories.count
        {
            mCategoryNoteCount[i] = 0
        }
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Notes")
        var results: [NSManagedObject] = []
        do
        {
            results = try context.fetch(fetchRequest)
        }
        catch
        {
            print(error)
        }
        for result in results
        {
            if let category = result.value(forKey: "category") as? String, let index = mCategories.firstIndex(of: category)
            {
                if mCategoryNoteCount[index] == nil
                {
                    mCategoryNoteCount[index] = 1
                }
                else
                {
                    mCategoryNoteCount[index]! += 1
                }
            }
        }
    }
    
    
    /// Function to get a category at  a particular index. Designed for TableView Controller
    /// - Parameter at: Index of the Category
    /// - Throws: Throws InavlidIndexException if the passed index is greated than Categories
    /// - Returns: Name of the category
    internal func getCategory(at: Int) throws -> String
    {
        if mCategories.count <= at
        {
            throw CustomExceptions.InavlidIndexException
        }
        return mCategories[at]
    }
    
    /// Adds Category into the Categories Array. The function also sorts the Category Names and Saves the Category in CoreData.
    /// - Parameter named: Name of the Category
    /// - Parameter context: NSManagedObjectContext object to be able to access Database
    internal func addCategory(named: String, context: NSManagedObjectContext)
    {
        mCategories.append(named)
        mCategories.sort()
        addCategoryInDatabase(named: named,context: context)
        loadCategoryNoteCount(context: context)
    }
    
    /// Adds Category in CoreData
    /// - Parameters:
    ///   - named: Name of the Category
    ///   - context: NSManagedObjectContext object to be able to access Database
    private func addCategoryInDatabase(named: String, context: NSManagedObjectContext)
    {
        let new_category_entity = NSEntityDescription.insertNewObject(forEntityName: "Categories", into: context)
        new_category_entity.setValue(named, forKey: "category")
        do
        {
            try context.save()
        }
        catch
        {
            print(error)
        }
    }
    
    /// Removes Category from the Categories Array and removes also removes associated with that folder
    /// - Parameter withIndex: Index of the Category to be removed
    /// - Parameter context: NSManagedObjectContext object to be able to access Database
    internal func removeCategory(withIndex: Int, context: NSManagedObjectContext)
    {
        let category = mCategories.remove(at: withIndex)
        removeCategoryFromDatabase(withCategory: category, context: context)
        removeNotesFromDatabase(withCategory: category, context: context)
    }
    
    /// Removes a Category from CoreData
    /// - Parameters:
    ///   - withCategory: Category Name
    ///   - context: NSManagedObjectContext object to be able to access Database
    private func removeCategoryFromDatabase(withCategory: String, context: NSManagedObjectContext)
    {
        let fetch_request = NSFetchRequest<NSFetchRequestResult>(entityName: "Categories")
        fetch_request.predicate = NSPredicate(format: "category = %@", withCategory)
        do
        {
            let test = try context.fetch(fetch_request)
            for t in test
            {
                let object_to_delete = t as! NSManagedObject
                context.delete(object_to_delete)
                do
                {
                    try context.save()
                }
                catch
                {
                    print(error)
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    
    /// Removes Notes from Database that is of one particular Category
    /// - Parameters:
    ///   - withCategory: Category Name
    ///   - context: NSManagedObjectContext object to be able to access Database
    private func removeNotesFromDatabase(withCategory: String, context: NSManagedObjectContext)
    {
        let fetch_request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        fetch_request.predicate = NSPredicate(format: "category = %@", withCategory)
        do
        {
            let test = try context.fetch(fetch_request)
            for t in test
            {
                let object_to_delete = t as! NSManagedObject
                context.delete(object_to_delete)
                do
                {
                    try context.save()
                }
                catch
                {
                    print(error)
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    
    /// Function to get Number of Categories
    /// - Returns: Number of Categories
    internal func getNumberOfCategories() -> Int
    {
        return mCategories.count
    }
    
    /// Function gets the Number of Notes for a particular Category
    /// - Parameter forCategory: Index of Category
    /// - Throws: InavlidIndexException if the passed index is greated than Categories
    /// - Returns: Number of Notes for a particular Category
    internal func getNumberOfNotes(forCategory: Int) throws -> Int
    {
        if mCategories.count <= forCategory
        {
            throw CustomExceptions.InavlidIndexException
        }
        return mCategoryNoteCount[forCategory]!
    }
    
    
    /// Gets the number of notes in Notes Array
    /// - Returns: Number of Notes
    internal func getNumberOfNotes() -> Int
    {
        return mNotes.count
    }
    
    
    /// Loads all the Notes of a particular Category in memory
    /// - Parameters:
    ///   - withCategory: Index of Category
    ///   - context: NSManagedObjectContext object to be able to access Database
    /// - Throws: InavlidIndexException if the passed index is greated than Categories
    internal func loadNotes(withCategory: Int, context: NSManagedObjectContext) throws
    {
        mNotes = []
        if mCategories.count <= withCategory
        {
            throw CustomExceptions.InavlidIndexException
        }
        let category = mCategories[withCategory]
        let fetch_request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        fetch_request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetch_request.predicate = NSPredicate(format: "category = %@", category)
        do
        {
            let notes = try context.fetch(fetch_request)
            for note1 in notes
            {
                let note = note1 as! NSManagedObject
                let title = note.value(forKey: "title") as! String
                let category = note.value(forKey: "category") as! String
                let date = note.value(forKey: "date") as! Date
                let audio_string = note.value(forKey: "audio") as? String
                let image_data = note.value(forKey: "image") as? NSData
                let lat = note.value(forKey: "lat") as? Double
                let long = note.value(forKey: "long") as? Double
                let msg = note.value(forKey: "message") as? String
                
                if image_data != nil
                {
                    let image = UIImage(data: image_data! as Data)
                    mNotes.append(Note(title: title, message: msg, lat: lat, long: long, image: image, date: date, categoryName: category, audioFileLocation: audio_string))
                }
                else
                {
                    mNotes.append(Note(title: title, message: msg, lat: lat, long: long, image: nil, date: date, categoryName: category, audioFileLocation: audio_string))
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    
    /// Function to get a Note with a particular category and index
    /// - Parameters:
    ///   - withCategory: Category of the Note
    ///   - at: Index of the Note
    /// - Throws: InavlidIndexException if the passed index is greated than Categories
    /// - Returns: Note with a particular category and index
    internal func getNote(at: Int) throws -> Note
    {
        if mNotes.count <= at
        {
            throw CustomExceptions.InavlidIndexException
        }
        return mNotes[at]
    }
    
    /// Function to add Note in the Notes Array
    /// - Parameters:
    ///   - note: Note Object
    ///   - context: NSManagedObjectContext object to be able to access Database
    /// - Throws: InvalidCategoryException if passed Note's Category does not exist
    internal func addNote(note: Note, context: NSManagedObjectContext) throws
    {
        if !mCategories.contains(note.mCategoryName)
        {
            throw CustomExceptions.InvalidCategoryException
        }
        mNotes.append(note)
        sortNotes()
        addNoteInDatabase(note: note, context: context)
        loadCategoryNoteCount(context: context)
    }
    
    
    /// Function to add Note in Database
    /// - Parameters:
    ///   - note: Note Object
    ///   - context: NSManagedObjectContext object to be able to access Database
    private func addNoteInDatabase(note: Note, context: NSManagedObjectContext)
    {
        let new_note_entity = NSEntityDescription.insertNewObject(forEntityName: "Notes", into: context)
        new_note_entity.setValue(note.mTitle, forKey: "title")
        new_note_entity.setValue(note.mDate, forKey: "date")
        new_note_entity.setValue(note.mCategoryName, forKey: "category")
        new_note_entity.setValue(note.mAudioFileLocation, forKey: "audio")
        new_note_entity.setValue(note.mImage?.pngData(), forKey: "image")
        new_note_entity.setValue(note.mLat, forKey: "lat")
        new_note_entity.setValue(note.mLong, forKey: "long")
        new_note_entity.setValue(note.mMessage, forKey: "message")
        do
        {
            try context.save()
        }
        catch
        {
            print(error)
        }
    }
    
    
    /// Function to sort the Notes on the basis of their title
    private func sortNotes()
    {
        mNotes.sort { (note1, note2) -> Bool in
            if note1.mTitle < note2.mTitle
            {
                return true
            }
            return false
        }
    }
    
    /// Function to delete Note from Notes Array
    /// - Parameters:
    ///   - note: Note Object to be deleted
    ///   - context: NSManagedObjectContext object to be able to access Database
    internal func deleteNote(note: Note, context: NSManagedObjectContext)
    {
        for i in 0..<mNotes.count
        {
            if mNotes[i] === note
            {
                mNotes.remove(at: i)
                break
            }
        }
        deleteNoteFromDatabase(note: note, context: context)
        loadCategoryNoteCount(context: context)
    }
    
    
    /// Deletes a Note
    /// - Parameters:
    ///   - at: Index of the Note
    ///   - context: NSManagedObjectContext object to be able to access Database
    /// - Throws: InvalidIndexException, if Index is greater than Notes Array
    internal func deleteNote(at: Int, context: NSManagedObjectContext) throws
    {
        if mNotes.count <= at
        {
            throw CustomExceptions.InavlidIndexException
        }
        let note = mNotes.remove(at: at)
        deleteNoteFromDatabase(note: note, context: context)
        loadCategoryNoteCount(context: context)
    }
    
    /// Function to delete Note from Database
    /// - Parameters:
    ///   - note: Note Object to be deleted
    ///   - context: NSManagedObjectContext object to be able to access Database
    private func deleteNoteFromDatabase(note: Note, context: NSManagedObjectContext)
    {
        let fetch_request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        let p1 = NSPredicate(format: "category = %@", note.mCategoryName)
        let p2 = NSPredicate(format: "title = %@", note.mTitle)
        fetch_request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1,p2])
        do
        {
            let notes = try context.fetch(fetch_request)
            for note1 in notes
            {
                let object_to_delete = note1 as! NSManagedObject
                context.delete(object_to_delete)
                do
                {
                    try context.save()
                }
                catch
                {
                    print(error)
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    
    /// Function to move Note from One Category to Another
    /// - Parameters:
    ///   - fromIndex: Index of the Category in the Origin Category
    ///   - toCategory: Category to where the Note is to be moved
    ///   - note: Note Object to be moved
    ///   - context: NSManagedObjectContext object to be able to access Database
    /// - Throws: InavlidIndexException if the passed index is greated than Categories
    internal func moveNote(note: Note, toCategory: Int, context: NSManagedObjectContext) throws
    {
        if mCategories.count <= toCategory
        {
            throw CustomExceptions.InavlidIndexException
        }
        deleteNote(note: note, context: context)
        note.mCategoryName = mCategories[toCategory]
        addNoteInDatabase(note: note, context: context)
        loadCategoryNoteCount(context: context)
    }
    
    
    /// Function to move Note from One Category to Another
    /// - Parameters:
    ///   - withIndex: Index of the Note to be moved
    ///   - toCategory: Category to where the Note is to be moved
    ///   - context:  NSManagedObjectContext object to be able to access Database
    /// - Throws: InavlidIndexException if the passed index is greated than Categories or if Index is greater than Notes Array
    internal func moveNote(withIndex: Int, toCategory: Int, context: NSManagedObjectContext) throws
    {
        if mCategories.count <= toCategory || mNotes.count <= withIndex
        {
            throw CustomExceptions.InavlidIndexException
        }
        let note = mNotes[withIndex]
        deleteNote(note: note, context: context)
        note.mCategoryName = mCategories[toCategory]
        addNoteInDatabase(note: note, context: context)
        loadCategoryNoteCount(context: context)
    }
    
    /// Deletes Mutiple Notes
    /// - Parameters:
    ///   - notes: Array of Notes to be Deleted
    ///   - context: NSManagedObjectContext object to be able to access Database
    internal func deleteMultipleNotes(notes: [Note], context: NSManagedObjectContext)
    {
        for note in notes
        {
            deleteNote(note: note, context: context)
        }
    }
    
    /// Deletes Mutiple Notes
    /// - Parameters:
    ///   - withIndexes: Indexes of Notes to be deleted
    ///   - context: NSManagedObjectContext object to be able to access Database
    /// - Throws: InvalidIndexException, if Index is greater than Notes Array
    internal func deleteMultipleNotes(withIndexes: [Int], context: NSManagedObjectContext) throws
    {
        for index in withIndexes.reversed()
        {
            try deleteNote(at: index, context: context)
        }
    }
    
    /// Deletes Multiple Categories in one call
    /// - Parameters:
    ///   - categories: Array of Index of Categories to be deleted
    ///   - context: NSManagedObjectContext object to be able to access Database
    internal func deleteMultipleCategories(categories: [Int], context: NSManagedObjectContext)
    {
        for category in categories
        {
            removeCategory(withIndex: category, context: context)
        }
    }
    
    /// Function to move multiple Notes from One Category to Another
    /// - Parameters:
    ///   - fromCategory: Origin Category Name
    ///   - fromIndex: Index of the Category in the Origin Category
    ///   - toCategory: Category to where the Note is to be moved
    ///   - context: NSManagedObjectContext object to be able to access Database
    ///   - notes: Array of the Notes to be Moved
    /// - Throws: InavlidIndexException if the passed index is greated than Categories or if Index is greater than Notes Array
    internal func moveNotes(notes: [Note], toCategory: Int, context: NSManagedObjectContext) throws
    {
        if mCategories.count <= toCategory
        {
            throw CustomExceptions.InavlidIndexException
        }
        for note in notes
        {
            try moveNote(note: note, toCategory: toCategory, context: context)
        }
    }
    
    /// Function to move multiple Notes from One Category to Another
    /// - Parameters:
    ///   - fromCategory: Origin Category Name
    ///   - fromIndex: Index of the Category in the Origin Category
    ///   - toCategory: Category to where the Note is to be moved
    ///   - context: NSManagedObjectContext object to be able to access Database
    ///   - notes: Array of the Notes to be Moved
    /// - Throws: InavlidIndexException if the passed index is greated than Categories  or if Index is greater than Notes Array
    internal func moveNotes(withIndexes: [Int], toCategory: Int, context: NSManagedObjectContext) throws
    {
        print("Got Number of Notes: \(withIndexes.count)")
        if mCategories.count <= toCategory
        {
            throw CustomExceptions.InavlidIndexException
        }
        for i in 0..<mNotes.count
        {
            print("note \(mNotes[i].mTitle) i: \(i)")
        }
        let indexes = withIndexes
        for index in indexes.sorted().reversed()
        {
            try moveNote(withIndex: index, toCategory: toCategory, context: context)
        }
    }
    
    /// Function to update Category
    /// - Parameters:
    ///   - oldCategory: Index of the Old Category
    ///   - newCategory: Name of the new Category
    ///   - context: NSManagedObjectContext object to be able to access Database
    internal func updateCategory(oldCategory: Int, newCategory: String, context: NSManagedObjectContext)
    {
        removeCategory(withIndex: oldCategory, context: context)
        addCategory(named: newCategory, context: context)
    }
    
    /// Function to update a Note
    /// - Parameters:
    ///   - oldNote: Object of the Note to be replaced
    ///   - newNote: Object of the Note to be replaced with
    ///   - context: NSManagedObjectContext object to be able to access Database
    /// - Throws: InvalidCategoryException if passed Note's Category does not exist
    internal func updateNote(oldNote: Note, newNote: Note, context: NSManagedObjectContext) throws
    {
        deleteNote(note: oldNote, context: context)
        try addNote(note: newNote, context: context)
    }
    
    /// Function to update a Note
    /// - Parameters:
    ///   - newNote: Object of the Note to be replaced with
    ///   - context: NSManagedObjectContext object to be able to access Database
    ///   - withIndex: Index of the note to be deleted
    /// - Throws: InvalidCategoryException if passed Note's Category does not exist  or if Index is greater than Notes Array
    internal func updateNote(oldNote withIndex: Int, newNote: Note, context: NSManagedObjectContext) throws
    {
        try deleteNote(at: withIndex, context: context)
        try addNote(note: newNote, context: context)
    }
    
    /// Function loads all the Categories in memory
    /// - Parameter context: It is NSManagedObjectContext to be able to access Database
    /// - Parameter withPredicate: Predicate to be searched with
    internal func loadAllCategories(context: NSManagedObjectContext, withPredicate: NSPredicate)
    {
        mCategories = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Categories")
        fetchRequest.predicate = withPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true)]
        var results: [NSManagedObject] = []
        do
        {
            results = try context.fetch(fetchRequest)
        }
        catch
        {
            print(error)
        }
        for result in results
        {
            mCategories.append( result.value(forKey: "category") as! String)
        }
        loadCategoryNoteCount(context: context, withPredicate: withPredicate)
    }
    
    /// Counts the Number of Notes grouped by Category
    /// - Parameter context: NSManagedObjectContext to be able to access Database
    /// - Parameter withPredicate: Predicate to be searched with
    private func loadCategoryNoteCount(context: NSManagedObjectContext, withPredicate: NSPredicate)
    {
        mCategoryNoteCount = [:]
        for i in 0..<mCategories.count
        {
            mCategoryNoteCount[i] = 0
        }
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Notes")
        var results: [NSManagedObject] = []
        do
        {
            results = try context.fetch(fetchRequest)
        }
        catch
        {
            print(error)
        }
        for result in results
        {
            if let category = result.value(forKey: "category") as? String, let index = mCategories.firstIndex(of: category)
            {
                if mCategoryNoteCount[index] == nil
                {
                    mCategoryNoteCount[index] = 1
                }
                else
                {
                    mCategoryNoteCount[index]! += 1
                }
            }
        }
    }
    
    /// Loads all the Notes of a particular Category in memory
    /// - Parameters:
    ///   - withCategory: Index of Category
    ///   - context: NSManagedObjectContext object to be able to access Database
    /// - Throws: InavlidIndexException if the passed index is greated than Categories
    internal func loadNotes(withCategory: Int, context: NSManagedObjectContext, withPredicate: NSCompoundPredicate) throws
    {
        mNotes.removeAll()
        if mCategories.count <= withCategory
        {
            throw CustomExceptions.InavlidIndexException
        }
        let category = mCategories[withCategory]
        let fetch_request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        fetch_request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let predicate1 = NSPredicate(format: "category = %@", category)
        fetch_request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, withPredicate])
        do
        {
            let notes = try context.fetch(fetch_request)
            for note1 in notes
            {
                let note = note1 as! NSManagedObject
                let title = note.value(forKey: "title") as! String
                let category = note.value(forKey: "category") as! String
                let date = note.value(forKey: "date") as! Date
                let audio_string = note.value(forKey: "audio") as? String
                let image_data = note.value(forKey: "image") as? NSData
                let lat = note.value(forKey: "lat") as? Double
                let long = note.value(forKey: "long") as? Double
                let msg = note.value(forKey: "message") as? String
                
                if image_data != nil
                {
                    let image = UIImage(data: image_data! as Data)
                    mNotes.append(Note(title: title, message: msg, lat: lat, long: long, image: image, date: date, categoryName: category, audioFileLocation: audio_string))
                }
                else
                {
                    mNotes.append(Note(title: title, message: msg, lat: lat, long: long, image: nil, date: date, categoryName: category, audioFileLocation: audio_string))
                }
            }
        }
        catch
        {
            print(error)
        }
    }
}
