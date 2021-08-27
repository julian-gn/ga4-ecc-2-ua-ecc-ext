___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "GA4 ecommerce to UA EEC",
  "categories": [
    "ANALYTICS",
    "TAG_MANAGEMENT",
    "UTILITY"
  ],
  "description": "This variable turns a GA4 ecommerce datalayer object into Universal Analytics (GA3) enhanced ecommerce format.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "LABEL",
    "name": "description1",
    "displayName": "This variable turns a GA4 ecommerce dataLayer object into Enhanced Ecommerce format. It requires the GA4 ecommerce event name as input to provide the relevant Enhanced ecommerce output."
  },
  {
    "type": "LABEL",
    "name": "description1.1",
    "displayName": "Note: the new events add_shipping_info and add_payment_info are mapped to checkout step 2 and 3, respectively."
  },
  {
    "type": "RADIO",
    "name": "autoOption",
    "displayName": "Event Detection",
    "radioItems": [
      {
        "value": "auto",
        "displayValue": "Auto detect GA4 ecommerce events"
      },
      {
        "value": "manual",
        "displayValue": "Manually declare GA4 ecommerce events"
      }
    ],
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "ga4event",
    "displayName": "GA4 ecommerce event name",
    "simpleValueType": true,
    "help": "To build the correct Enhanced Ecommerce object, the GA4 ecommerce event name is required.",
    "enablingConditions": [
      {
        "paramName": "autoOption",
        "paramValue": "manual",
        "type": "EQUALS"
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "mapCheckoutSteps",
    "displayName": "Map Checkout Steps",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Event",
        "name": "stepEvent",
        "type": "SELECT",
        "selectItems": [
          {
            "value": "cart",
            "displayValue": "view_cart"
          },
          {
            "value": "begin",
            "displayValue": "begin_checkout"
          },
          {
            "value": "payment",
            "displayValue": "add_payment_info"
          },
          {
            "value": "shipping",
            "displayValue": "add_shipping_info"
          }
        ],
        "isUnique": true
      },
      {
        "defaultValue": "",
        "displayName": "Step",
        "name": "stepNum",
        "type": "TEXT",
        "valueValidators": [
          {
            "type": "NUMBER"
          }
        ]
      }
    ],
    "help": "Enter the Checkout Steps (UA) to which you want to map the GA4 Events",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "mapCustomItemParameters",
    "displayName": "Map custom item parameters to custom definitions",
    "groupStyle": "ZIPPY_OPEN_ON_PARAM",
    "subParams": [
      {
        "type": "LABEL",
        "name": "description2",
        "displayName": "Item parameters from the documentation are mapped automatically by this variable, but maybe you have custom parameters in your implementation. Enter your custom item parameters here and map them to the correct custom definition for Enhanced Ecommerce (e.g. dimensionX, metricY)."
      },
      {
        "type": "SIMPLE_TABLE",
        "name": "customItemParametersMapTable",
        "displayName": "",
        "simpleTableColumns": [
          {
            "defaultValue": "",
            "displayName": "Custom item parameter name",
            "name": "customItemParameter",
            "type": "TEXT"
          },
          {
            "defaultValue": "",
            "displayName": "Custom dimension/metric",
            "name": "customDefinition",
            "type": "TEXT",
            "valueValidators": [
              {
                "type": "REGEX",
                "args": [
                  "^(dimension|metric)\\d+"
                ],
                "errorMessage": "This value can only be the word \u0027dimension\u0027 or \u0027metric\u0027 directly followed by one or more digits"
              }
            ]
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const copyFromDataLayer = require('copyFromDataLayer');
const makeTableMap = require('makeTableMap');
const logToConsole = require('logToConsole');

const ev = data.autoOption === 'auto' ? copyFromDataLayer('event') : data.ga4event;
const customParameterMap = data.customItemParametersMapTable ? makeTableMap(data.customItemParametersMapTable, 'customItemParameter', 'customDefinition') : undefined;

const mapItemToProduct = (i) => {
  let cat = '';
  for (let index in i) {
    if (index.indexOf('category') > -1) {
      if (cat.length !== 0) {
        cat += '/';
      }
      cat += i[index];
    }
  }
  
  const productObj = {
    id: i.item_id,
    name: i.item_name,
    price: i.price,
    brand: i.item_brand,
    variant: i.item_variant,
    quantity: i.quantity,
    coupon: i.coupon,
    category: cat || undefined
  };
  
  if (customParameterMap) {
    for (let key in customParameterMap) {
      if (i[key]) {
        productObj[customParameterMap[key]] = i[key];
      }
    }
  }
  return productObj;
};

const mapPromotionToPromotion = (i) => {
  return {
    name: i.promotion_name,
    id: i.promotion_id,
    creative: i.creative_name,
    position: i.creative_slot
  };
};

const ec = copyFromDataLayer('ecommerce', 1) || {};
const eec = {};
eec.currencyCode = ec.currency;
const steps = makeTableMap(data.mapCheckoutSteps, 'stepEvent', 'stepNum');
logToConsole(steps);

if (ec.hasOwnProperty('items')) {
  if (ev === 'view_promotion') {
    eec.promoView = {};
    eec.promoView.promotions = ec.items.map((item) => mapPromotionToPromotion(item));
    return {ecommerce: eec};
  }
  
  if (ev === 'select_promotion') {
    eec.promoClick = {};
    eec.promoClick.promotions = ec.items.map((item) => mapPromotionToPromotion(item));
    return {ecommerce: eec};
  }
  
  if (ev === 'view_item_list') {
    eec.impressions = ec.items.map((item) => {
      const impression = mapItemToProduct(item);
      impression.list = item.item_list_name;
      impression.position = item.index;
      return impression;
    });
    return {ecommerce: eec};
  }
  
  if (ev === 'select_item') {
    eec.click = {};
    eec.click.products = ec.items.map((item) => {
      const product = mapItemToProduct(item);
      product.position = item.index;
      const listvar = item.item_list_name;
      if (listvar) {
        eec.click.actionField = {list: listvar};
      }
      return product;
    });
    return {ecommerce: eec};
  }
  
  if (ev === 'view_item') {
    eec.detail = {};
    eec.detail.products = ec.items.map((item) => {
      const product = mapItemToProduct(item);
      product.position = item.index;
      const listvar = item.item_list_name;
      if (listvar) {
        eec.detail.actionField = {list: listvar};
      }
      return product;
    });
    return {ecommerce: eec};
  }

  if (ev === 'add_to_cart') {
    eec.add = {};
    eec.add.products = ec.items.map((item) => {
      const product = mapItemToProduct(item);
      return product;
    });
    return {ecommerce: eec};
  }
  
  if (ev === 'remove_from_cart') {
    eec.remove = {};
    eec.remove.products = ec.items.map((item) => {
      const product = mapItemToProduct(item);
      return product;
    });
    return {ecommerce: eec};    
  }
  
  if (ev === 'begin_checkout') {
    eec.checkout = {actionField: {step: steps.begin}};
    eec.checkout.products = ec.items.map((item) => {
      const product = mapItemToProduct(item);
      return product;
    });
    return {ecommerce: eec};
  }
  
  if (ev === 'view_cart') {
    eec.checkout = {actionField: {step: steps.cart}};
    eec.checkout.products = ec.items.map((item) => {
      const product = mapItemToProduct(item);
      return product;
    });
    return {ecommerce: eec};
  }
  
  if(ev === 'add_shipping_info') {
    eec.checkout = {actionField: {step: steps.shipping, option: ec.shipping_tier}};
    return {ecommerce: eec};
  }
  
  if(ev === 'add_payment_info') {
    eec.checkout = {actionField: {step: steps.payment, option: ec.payment_type}};
    return {ecommerce: eec};
  }
  
  if (ev === 'purchase') {
    eec.purchase = {};
    eec.purchase.actionField = {
      id: ec.transaction_id,
      revenue: ec.value,
      tax: ec.tax,
      shipping: ec.shipping,
      affiliation: ec.affiliation,
      coupon: ec.coupon
    };
    eec.purchase.products = ec.items.map((item) => {
      const product = mapItemToProduct(item);
      product.position = item.index;
      const listvar = item.item_list_name;
      if (listvar) {
        eec.detail.actionField = {list: listvar};
      }
      return product;
    });
    return {ecommerce: eec};
  }  
}


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "ecommerce"
              },
              {
                "type": 1,
                "string": "event"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: view_item input
  code: |-
    const mockData = {
      ga4event: 'view_item'
    };

    mock('copyFromDataLayer', (obj, version) => {
      if (obj === 'ecommerce') {
        return {
          event: 'view_item',
          items: [{
            item_name: 'naked statistics - charles wheelan',
            item_id: 'wheelan-nakedstatistics',
            price: 15,
            item_brand: 'ww norton',
            item_category: 'books',
            item_category2: 'non-fiction',
            item_category3: 'science',
            item_category4: 'statistics',
            item_variant: 'ebook',
            item_type: 'epub',
            quantity: 1
          }]
        };
      }
    });

    let variableResult = runCode(mockData);


    assertThat(variableResult).isNotEqualTo(undefined);
setup: ''


___NOTES___

Created on 21/07/2021, 14:16:24


