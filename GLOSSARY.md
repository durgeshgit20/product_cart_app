# Product Cart

A shopping app where a Shopper browses a catalog of Products, collects the ones they want to buy in a Cart, and keeps the ones they might buy later in a Wishlist.

## Language

**Shopper**:
The person using the app. There are no accounts, so a Shopper is one device.
_Avoid_: User, customer, account

**Product**:
An item in the catalog, with a price and a stock level that can change while the Shopper is browsing.
_Avoid_: Item, SKU

**Out of Stock**:
A Product that cannot currently be added to the Cart.

**Data Source**:
Where the catalog comes from: the Live API or Mock Data. The two are separate catalogs, so the same Product has a different identity in each.
_Avoid_: Environment, mode, backend

### Cart

**Cart**:
The Products the Shopper intends to buy now, each with a quantity. It lasts only for the current app session.
_Avoid_: Basket, bag

**Cart Item**:
One Product in the Cart, together with its quantity.
_Avoid_: Line item

### Wishlist

**Wishlist**:
The set of Products the Shopper wants and may buy later. A Product is either on it or not, with no quantity. It is kept on the device between sessions, and each Data Source has its own.
_Avoid_: Favourites, Saved Items, Save for Later

**Wishlisted**:
Describes a Product that is on the Wishlist. Any Product can be Wishlisted, including one that is Out of Stock.

**No Longer Available**:
Describes a Wishlisted Product that is missing from the current catalog. It stays on the Wishlist but cannot be Moved to Cart.
_Avoid_: Deleted, discontinued

**Move to Cart**:
The action that takes a Wishlisted Product off the Wishlist and adds one of it to the Cart. Not possible for a Product that is Out of Stock or No Longer Available.
_Avoid_: Add to Cart (from Wishlist)

**Price Drop**:
When a Wishlisted Product's current price is lower than its price at the moment it was Wishlisted.
_Avoid_: Discount, sale
