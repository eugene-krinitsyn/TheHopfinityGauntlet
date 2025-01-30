import Foundation
import NetworkSession

public extension ShopifyAPI {
  struct Customer: Configurable, Sendable {
    public var configuration: ShopifyAPI.Configuration
  }
}

public extension ShopifyAPI.Customer {
  func requestOrders() -> NetworkRequest<OrdersModel> {
    let url = configuration.basePath + "/customer/api/unstable/graphql?operation=Orders"
    let params: [String: Any] = [
      "operationName": "Orders",
      "variables": [
        "isBusinessCustomer": false,
        "first": 50,
        "businessAccountSortKey": "PROCESSED_AT",
        "personalAccountSortKey": "PROCESSED_AT",
        "reverse": true,
        "companyId": "gid://shopify/Company/0",
        "query": "(purchasing_entity:Customer)"
      ],
      "query": "query Orders($isBusinessCustomer: Boolean!, $companyId: ID!, $before: String, $after: String, $first: Int, $last: Int, $query: String, $businessAccountSortKey: OrderByContactSortKeys, $personalAccountSortKey: OrderSortKeys, $reverse: Boolean!) {\n  customer @skip(if: $isBusinessCustomer) {\n    id\n    orders(\n      first: $first\n      last: $last\n      before: $before\n      after: $after\n      sortKey: $personalAccountSortKey\n      reverse: $reverse\n      query: $query\n    ) {\n      nodes {\n        id\n        ...OrderNode\n        __typename\n      }\n      pageInfo {\n        ...PageInfo\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  company(id: $companyId) @include(if: $isBusinessCustomer) {\n    id\n    profile {\n      id\n      hasPermissionOnLocations(permissions: [VIEW], scope: ANY, resource: ORDER)\n      orders(\n        first: $first\n        last: $last\n        before: $before\n        after: $after\n        sortKey: $businessAccountSortKey\n        reverse: $reverse\n        query: $query\n      ) {\n        nodes {\n          id\n          ...OrderNode\n          poNumber\n          __typename\n        }\n        pageInfo {\n          ...PageInfo\n          __typename\n        }\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment OrderNode on Order {\n  id\n  name\n  confirmationNumber\n  customerFulfillmentStatus\n  automaticDeferredPaymentCollection\n  totalPrice {\n    amount\n    currencyCode\n    __typename\n  }\n  processedAt\n  cancelledAt\n  editSummary {\n    changes {\n      id\n      delta\n      lineItem {\n        id\n        quantity\n        title\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  lineItems: lineItemContainers {\n    ... on RemainingLineItemContainer {\n      id\n      lineItems(first: 4) {\n        nodes {\n          id\n          lineItem {\n            id\n            name\n            quantity\n            image {\n              id\n              altText\n              url\n              __typename\n            }\n            __typename\n          }\n          __typename\n        }\n        pageInfo {\n          hasNextPage\n          endCursor\n          __typename\n        }\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  fulfillmentDates: fulfillments(\n    first: 1\n    sortKey: CREATED_AT\n    reverse: true\n    query: \"NOT status:CANCELLED\"\n  ) {\n    nodes {\n      id\n      createdAt\n      events(first: 1, sortKey: HAPPENED_AT, reverse: true) {\n        nodes {\n          id\n          happenedAt\n          __typename\n        }\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  lineItemsSummary {\n    lineItemCount\n    totalQuantityOfLineItems\n    totalQuantityOfTipLineItems\n    __typename\n  }\n  paymentInformation {\n    paymentStatus\n    paymentCollectionUrl\n    totalOutstandingAmount {\n      amount\n      currencyCode\n      __typename\n    }\n    paymentTerms {\n      id\n      overdue\n      paymentTermsType\n      lastSchedule: paymentSchedules(first: 1, reverse: true) {\n        nodes {\n          id\n          dueAt\n          completed\n          __typename\n        }\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  latestFulfillmentDeliveryDate\n  purchasingEntity {\n    ... on PurchasingCompany {\n      location {\n        id\n        name\n        market {\n          id\n          webPresence {\n            id\n            rootUrls {\n              url\n              locale\n              __typename\n            }\n            subfolderSuffix\n            __typename\n          }\n          __typename\n        }\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  customer {\n    id\n    displayName\n    __typename\n  }\n  reorderPath\n  market {\n    id\n    webPresence {\n      id\n      domain {\n        id\n        type\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  returnInformation {\n    nonReturnableSummary {\n      summaryMessage\n      __typename\n    }\n    __typename\n  }\n  transactions {\n    id\n    type\n    status\n    __typename\n  }\n  __typename\n}\n\nfragment PageInfo on PageInfo {\n  hasNextPage\n  hasPreviousPage\n  startCursor\n  endCursor\n  __typename\n}"
    ]
    return NetworkRequest(URLString: url)
      .setMethod(.POST)
      .setParameters(.json(params))
      .setHeaders(["Authorization": "shcat_eyJraWQiOiIwIiwiYWxnIjoiRUQyNTUxOSJ9.eyJzaG9wSWQiOjY5MTI4ODcsImNpZCI6IjJmZDkwNjFhLWM2YzQtNDhhMi1iOGQ4LWJlNzcyY2ZjOTY5YyIsImlhdCI6MTczNzMwNjk1NiwiZXhwIjoxNzM3MzEwNTU2LCJpc3MiOiJodHRwczpcL1wvc2hvcGlmeS5jb21cL2F1dGhlbnRpY2F0aW9uXC82OTEyODg3Iiwic3ViIjo4NDM5ODU1NjQ1MDEwLCJzY29wZSI6Im9wZW5pZCBlbWFpbCBjdXN0b21lci1hY2NvdW50LWFwaTpmdWxsIn0.dz1VV-WT33C1V1peam2c4bUu7BA7WkFGXAKWFzBV8NlZYl3lZeavOr1s_Ln6Wb1kZ4uy6HcOloAHk50kZM9DBg"])
  }
}
