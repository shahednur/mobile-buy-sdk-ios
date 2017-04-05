//
//  ClientQuery.swift
//  Storefront
//
//  Created by Shopify.
//  Copyright (c) 2017 Shopify Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Buy
import Pay

final class ClientQuery {

    // ----------------------------------
    //  MARK: - Storefront -
    //
    static func queryForCollections(limit: Int, after cursor: String? = nil, productLimit: Int = 25, productCursor: String? = nil) -> Storefront.QueryRootQuery {
        return Storefront.buildQuery { $0
            .shop { $0
                .collections(first: Int32(limit), after: cursor) { $0
                    .pageInfo { $0
                        .hasNextPage()
                    }
                    .edges { $0
                        .cursor()
                        .node { $0
                            .id()
                            .title()
                            .descriptionHtml()
                            .image { $0
                                .src()
                            }
                            
                            .products(first: Int32(productLimit), after: productCursor) { $0
                                .fragmentForStandardProduct()
                            }
                        }
                    }
                }
            }
        }
    }
    
    static func queryForProducts(in collection: CollectionViewModel, limit: Int, after cursor: String? = nil) -> Storefront.QueryRootQuery {
        
        return Storefront.buildQuery { $0
            .node(id: collection.model.node.id) { $0
                .onCollection { $0
                    .products(first: Int32(limit), after: cursor) { $0
                        .fragmentForStandardProduct()
                    }
                }
            }
        }
    }
    
    // ----------------------------------
    //  MARK: - Checkout -
    //
    static func mutationForCreateCheckout(with cartItems: [CartItem]) -> Storefront.MutationQuery {
        let lineItems = cartItems.map { item in
            Storefront.LineItemInput(variantId: GraphQL.ID(rawValue: item.variant.id), quantity: Int32(item.quantity))
        }
        
        let checkoutInput = Storefront.CheckoutCreateInput(lineItems: lineItems)
        
        return Storefront.buildMutation { $0
            .checkoutCreate(input: checkoutInput) { $0
                .checkout { $0
                    .fragmentForCheckout()
                }
            }
        }
    }
    
    static func mutationForUpdateCheckout(_ id: String, updatingShippingAddress address: PayPostalAddress) -> Storefront.MutationQuery {
        
//        let addressInput = Storefront.MailingAddressInput(
//            city:     address.city,
//            country:  address.country,
//            province: address.province,
//            zip:      address.zip
//        )
        
        
        let addressInput = Storefront.MailingAddressInput(
            address1:  "80 Spadina",
            address2:  "",
            city:      "Toronto",
            country:   "Canada",
            firstName: "John",
            lastName:  "Smith",
            province:  "ON",
            zip:       "M5V 2J4"
        )
        
        let updateInput = Storefront.CheckoutShippingAddressUpdateInput(shippingAddress: addressInput, checkoutId: GraphQL.ID(rawValue: id))
        
        return Storefront.buildMutation { $0
            .checkoutShippingAddressUpdate(input: updateInput) { $0
                .userErrors { $0
                    .field()
                    .message()
                }
                .checkout { $0
                    .fragmentForCheckout()
                }
            }
        }
    }
    
//    static func mutationForUpdateCheckout(_ id: String, updatingBillingAddress address: PayPostalAddress) -> Storefront.MutationQuery {
//        
////        let addressInput = Storefront.MailingAddressInput(
////            city:     address.city,
////            country:  address.country,
////            province: address.province,
////            zip:      address.zip
////        )
//        
//        let addressInput = Storefront.MailingAddressInput(
//            address1:  "80 Spadina",
//            address2:  "",
//            city:      "Toronto",
//            country:   "Canada",
//            firstName: "John",
//            lastName:  "Smith",
//            province:  "ON",
//            zip:       "M5V 2J4"
//        )
//        
//        let updateInput = Storefront.CheckoutBillingAddressUpdateInput(shippingAddress: addressInput, checkoutId: GraphQL.ID(rawValue: id))
//        
//        return Storefront.buildMutation { $0
//            .checkoutBillingAddressUpdate(input: updateInput) { $0
//                .userErrors { $0
//                    .field()
//                    .message()
//                }
//                .checkout { $0
//                    .fragmentForCheckout()
//                }
//            }
//        }
//    }
    
    static func mutationForUpdateCheckout(_ id: String, updatingShippingRate shippingRate: PayShippingRate) -> Storefront.MutationQuery {
        
        let updateInput = Storefront.CheckoutShippingLineUpdateInput(checkoutId: GraphQL.ID(rawValue: id), shippingRateHandle: shippingRate.handle)
        
        return Storefront.buildMutation { $0
            .checkoutShippingLineUpdate(input: updateInput) { $0
                .userErrors { $0
                    .field()
                    .message()
                }
                .checkout { $0
                    .fragmentForCheckout()
                }
            }
        }
    }
    
    static func mutationForUpdateCheckout(_ id: String, updatingEmail email: String) -> Storefront.MutationQuery {
        
        let updateInput = Storefront.CheckoutEmailUpdateInput(checkoutId: GraphQL.ID(rawValue: id), email: email)
        
        return Storefront.buildMutation { $0
            .checkoutEmailUpdate(input: updateInput) { $0
                .userErrors { $0
                    .field()
                    .message()
                }
                .checkout { $0
                    .fragmentForCheckout()
                }
            }
        }
    }
    
    static func mutationForCompleteCheckoutUsingApplePay(_ checkout: PayCheckout, billingAddress: PayAddress, token: String, idempotencyToken: String) -> Storefront.MutationQuery {
        
        let mailingAddress = Storefront.MailingAddressInput(
            address1:  billingAddress.addressLine1,
            address2:  billingAddress.addressLine2,
            city:      billingAddress.city,
            country:   billingAddress.country,
            firstName: billingAddress.firstName,
            lastName:  billingAddress.lastName,
            province:  billingAddress.province,
            zip:       billingAddress.zip
        )
        
        let tokenizedInput = Storefront.CheckoutCompleteWithTokenizedPaymentInput(
            checkoutId:     GraphQL.ID(rawValue: checkout.id),
            amount:         checkout.paymentDue,
            idempotencyKey: idempotencyToken,
            billingAddress: mailingAddress,
            type:           CheckoutViewModel.PaymentType.applePay.rawValue,
            paymentData:    token
        )
        
        return Storefront.buildMutation { $0
            .checkoutCompleteWithTokenizedPayment(input: tokenizedInput) { $0
                .userErrors { $0
                    .field()
                    .message()
                }
                .payment { $0
                    .id()
                    .ready()
                    .test()
                    .amount()
                    .checkout { $0
                        .fragmentForCheckout()
                    }
                    .creditCard { $0
                        .firstDigits()
                        .lastDigits()
                        .maskedNumber()
                        .brand()
                        .firstName()
                        .lastName()
                        .expiryMonth()
                        .expiryYear()
                    }
                }
            }
        }
    }
    
    static func queryShippingRatesForCheckout(_ id: String) -> Storefront.QueryRootQuery {
        
        return Storefront.buildQuery { $0
            .node(id: GraphQL.ID(rawValue: id)!) { $0
                .onCheckout { $0
                    .fragmentForCheckout()
                    .availableShippingRates { $0
                        .ready()
                        .shippingRates { $0
                            .handle()
                            .price()
                            .title()
                        }
                    }
                }
            }
        }
    }
}
