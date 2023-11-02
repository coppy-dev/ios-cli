import XCTest
@testable import coppyCli

final class CoppyParserTests: XCTestCase {
    
    func testParsesSimpleObject() {
        let obj = ["header": "Header", "body": "Body text", "optional": ""] as [String : Any]
        
        let result = CoppyParser.parseJson(obj: obj, name: "CoppyContent")
        
        XCTAssertEqual(result.name, "CoppyContent")
        XCTAssertEqual(result.fields.count, 3)
        
        let headerField = result.fields.first(where: { $0.key == "header" })
        XCTAssertNotNil(headerField)
        XCTAssertEqual(headerField?.type, "string")
        XCTAssertFalse(headerField?.optional ?? true)
        XCTAssertNil(headerField?.cl)
        
        let bodyField = result.fields.first(where: { $0.key == "body" })
        XCTAssertNotNil(bodyField)
        XCTAssertEqual(bodyField?.type, "string")
        XCTAssertFalse(bodyField?.optional ?? true)
        XCTAssertNil(bodyField?.cl)
        
        let optionalField = result.fields.first(where: { $0.key == "optional" })
        XCTAssertNotNil(optionalField)
        XCTAssertEqual(optionalField?.type, "string")
        XCTAssertTrue(optionalField?.optional ?? false)
        XCTAssertNil(optionalField?.cl)
    }

    func testParsesSimpleObjectWithNotSupportedType() {
        let obj = ["header": "Header", "body": "Body text", "check": true] as [String : Any]
        
        let result = CoppyParser.parseJson(obj: obj, name: "CoppyContent")
        
        XCTAssertEqual(result.name, "CoppyContent")
        XCTAssertEqual(result.fields.count, 2)
        
        let headerField = result.fields.first(where: { $0.key == "header" })
        XCTAssertNotNil(headerField)
        XCTAssertEqual(headerField?.type, "string")
        XCTAssertFalse(headerField?.optional ?? true)
        XCTAssertNil(headerField?.cl)
        
        let bodyField = result.fields.first(where: { $0.key == "body" })
        XCTAssertNotNil(bodyField)
        XCTAssertEqual(bodyField?.type, "string")
        XCTAssertFalse(bodyField?.optional ?? true)
        XCTAssertNil(bodyField?.cl)
    }
    
    func testParsesNestedObject() {
        let obj = [
            "header": "Header",
            "body": "Body text",
            "link": ["title": "title", "url": "url"]
        ] as [String : Any]
        
        let result = CoppyParser.parseJson(obj: obj, name: "CoppyContent")
        
        XCTAssertEqual(result.name, "CoppyContent")
        XCTAssertEqual(result.fields.count, 3)
        
        let headerField = result.fields.first(where: { $0.key == "header" })
        XCTAssertNotNil(headerField)
        XCTAssertEqual(headerField?.type, "string")
        XCTAssertFalse(headerField?.optional ?? true)
        XCTAssertNil(headerField?.cl)
        
        let bodyField = result.fields.first(where: { $0.key == "body" })
        XCTAssertNotNil(bodyField)
        XCTAssertEqual(bodyField?.type, "string")
        XCTAssertFalse(bodyField?.optional ?? true)
        XCTAssertNil(bodyField?.cl)
        
        let linkField = result.fields.first(where: { $0.key == "link" })
        XCTAssertNotNil(linkField)
        XCTAssertEqual(linkField?.type, "object")
        XCTAssertFalse(linkField?.optional ?? true)
        
        let linkClass = linkField?.cl
        XCTAssertNotNil(linkClass)
        XCTAssertEqual(linkClass?.name, "CoppyContentLink")
        XCTAssertEqual(linkClass?.fields.count, 2)
        
        let titleField = linkClass?.fields.first(where: { $0.key == "title" })
        XCTAssertNotNil(titleField)
        XCTAssertEqual(titleField?.type, "string")
        XCTAssertFalse(titleField?.optional ?? true)
        XCTAssertNil(titleField?.cl)
        
        let urlField = linkClass?.fields.first(where: { $0.key == "url" })
        XCTAssertNotNil(urlField)
        XCTAssertEqual(urlField?.type, "string")
        XCTAssertFalse(urlField?.optional ?? true)
        XCTAssertNil(urlField?.cl)
    }
    
    func testParsesNestedObjectWithArray() {
        let obj = [
            "header": "Header",
            "body": "Body text",
            "links": [["title": "title", "url": "url"], ["title": "title", "url": "url", "optional": "true"]],
            "urls": [["title": "title", "url": "url", "optional": "true"], ["title": "title", "url": "url"]],
            "benefits": ["First", "Second"],
            "emptyArray": [],
            "incorrectList": ["String", ["title": "title"]],
            "incorrectList2": [["title": "Title"], ["title": ["someField": "field"]]]
        ] as [String : Any]
        
        let result = CoppyParser.parseJson(obj: obj, name: "CoppyContent")
        
        XCTAssertEqual(result.name, "CoppyContent")
        XCTAssertEqual(result.fields.count, 5)
        
        let headerField = result.fields.first(where: { $0.key == "header" })
        XCTAssertNotNil(headerField)
        XCTAssertEqual(headerField?.type, "string")
        XCTAssertFalse(headerField?.optional ?? true)
        XCTAssertNil(headerField?.cl)
        
        let bodyField = result.fields.first(where: { $0.key == "body" })
        XCTAssertNotNil(bodyField)
        XCTAssertEqual(bodyField?.type, "string")
        XCTAssertFalse(bodyField?.optional ?? true)
        XCTAssertNil(bodyField?.cl)
        
        // Links
        let linksField = result.fields.first(where: { $0.key == "links" })
        XCTAssertNotNil(linksField)
        XCTAssertEqual(linksField?.type, "array")
        XCTAssertFalse(linksField?.optional ?? true)
        
        let linksClass = linksField?.cl
        XCTAssertNotNil(linksClass)
        XCTAssertEqual(linksClass?.name, "CoppyContentLinks")
        XCTAssertEqual(linksClass?.fields.count, 3)
        
        let linksTitleField = linksClass?.fields.first(where: { $0.key == "title" })
        XCTAssertNotNil(linksTitleField)
        XCTAssertEqual(linksTitleField?.type, "string")
        XCTAssertFalse(linksTitleField?.optional ?? true)
        XCTAssertNil(linksTitleField?.cl)
        
        let linksUrlField = linksClass?.fields.first(where: { $0.key == "url" })
        XCTAssertNotNil(linksUrlField)
        XCTAssertEqual(linksUrlField?.type, "string")
        XCTAssertFalse(linksUrlField?.optional ?? true)
        XCTAssertNil(linksUrlField?.cl)
        
        let linksOptionalField = linksClass?.fields.first(where: { $0.key == "optional" })
        XCTAssertNotNil(linksOptionalField)
        XCTAssertEqual(linksOptionalField?.type, "string")
        XCTAssertTrue(linksOptionalField?.optional ?? false)
        XCTAssertNil(linksOptionalField?.cl)
        
        // Urls
        let urlsField = result.fields.first(where: { $0.key == "urls" })
        XCTAssertNotNil(urlsField)
        XCTAssertEqual(urlsField?.type, "array")
        XCTAssertFalse(urlsField?.optional ?? true)
        
        let urlsClass = urlsField?.cl
        XCTAssertNotNil(urlsClass)
        XCTAssertEqual(urlsClass?.name, "CoppyContentUrls")
        XCTAssertEqual(urlsClass?.fields.count, 3)
        
        let urlsTitleField = urlsClass?.fields.first(where: { $0.key == "title" })
        XCTAssertNotNil(urlsTitleField)
        XCTAssertEqual(urlsTitleField?.type, "string")
        XCTAssertFalse(urlsTitleField?.optional ?? true)
        XCTAssertNil(urlsTitleField?.cl)
        
        let urlsUrlField = urlsClass?.fields.first(where: { $0.key == "url" })
        XCTAssertNotNil(urlsUrlField)
        XCTAssertEqual(urlsUrlField?.type, "string")
        XCTAssertFalse(urlsUrlField?.optional ?? true)
        XCTAssertNil(urlsUrlField?.cl)
        
        let urlsOptionalField = urlsClass?.fields.first(where: { $0.key == "optional" })
        XCTAssertNotNil(urlsOptionalField)
        XCTAssertEqual(urlsOptionalField?.type, "string")
        XCTAssertTrue(urlsOptionalField?.optional ?? false)
        XCTAssertNil(urlsOptionalField?.cl)
        
        // Benefits
        let benefitsField = result.fields.first(where: { $0.key == "benefits" })
        XCTAssertNotNil(benefitsField)
        XCTAssertEqual(benefitsField?.type, "array")
        XCTAssertFalse(benefitsField?.optional ?? true)
        XCTAssertNil(benefitsField?.cl)
    }
}
