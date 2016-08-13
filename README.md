# VirtualTourist
VIRTUAL TOURIST

The Virtual Tourist app allows users to specify travel locations around the world, and create virtual photo albums for each location. The locations and photo albums are stored in Core Data and displayed via UICollectionView.


DESIGN APPROACH

The storyboard and VC UI design is probably fairly standard.

All flickr processing is in the SharedNetworkServices classes. This means that even when a UICollectionView refresh is needed a SharedNetworkServices func is called from the PhotoAlbumVC rather than having flickr code in the VC

Photo images are stored in Core Data (using the Allows External Storage option).

UICollectionvView process is via the standard delegates. The view is updated using a fetched results controller as Core Data is updated - no intervention required!

flickr downloads are initiated:
    1. When a pin is added after a long pin pressed (TravelLocationsVC)
    2. In the PhotoAlbumVC when:
        a. No photos exist for the selected pin AND there is no flckr download in process (such as when the long pin has been pressed but processing not complete)
        b. The user pressed the "New Collection" button


FOLDERS / FILES

The design has 5 primary folders:

1. Virtual Tourist - typical classesa and files, e.g. storyboard and collectionviewcell
2. VCs (View Controllers) - the 2 VCs
3. CoreDataServices - the Core Data Stack Manager
4. Model - Core Data model
5. Shared Services - various shared services clases:
    Constants               - constants used throughout the app. Stored here rather than have constants distributed across classes.
    GlobalVar               - global variable(s) stored in once place rather than distributed across classes.
    Status                  - statuses and status text
    SharedNetworkServices   - network (flickr) and related funcs
    SharedServices          - non-network shared services such as presenting message alerts
    SharedMethod            - list of shared methods generally in SharedNetworkServices and SharedServices. So don't need to remember in which classes various funcs are
