/// ZeroDark.cloud
///
/// Homepage      : https://www.zerodark.cloud
/// GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
/// Documentation : https://zerodarkcloud.readthedocs.io/en/latest
/// API Reference : https://apis.zerodark.cloud
///
/// Sample App: sample1

import Foundation

import CocoaLumberjack
import YapDatabase


/// We're using YapDatabase in this example.
/// You don't have to use it (but it's pretty awesome).
///
/// https://github.com/yapstudios/YapDatabase
///
class DBManager {
	
	public static var sharedInstance: DBManager = {
		let dbManager = DBManager()
		return dbManager
	}()
	
	private init() {
		// Configure logging level (for CocoaLumberjack)
	#if DEBUG
		dynamicLogLevel = .all
	#else
		dynamicLogLevel = .warning
	#endif
	}
	
	public func configureDatabase(_ db: YapDatabase) {
		
		// YapDatabase allows us to store any objects that conform to Swift's Codable protocol.
		// All we have to do is register the class.
		//
		// YapDatabase is a collection/key/value store.
		// So we're registering the class with the collection in which we're going to store instances of the class.

		
		
		// In addtion to being a collection/key/value store, YapDatabase comes with a bunch of extensions.
		// These extensions allow us to do a bunch of cool stuff such as:
		// - order & sort items in the database
		// - create various indexes on object properties (for searching, etc)
		// - full text search extension
		// - etc
		//
		// In this example, we create a few extensions for doing things such as
		// - sorting the lists for display in a tableView
		// - sorting the tasks (within each list) for display in a tableView
		// - etc

}

}
