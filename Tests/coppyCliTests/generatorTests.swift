import XCTest
@testable import coppyCli

final class CoppyGeneratorTests: XCTestCase {
    
    func testGenerateClasses_GeneratesSimpleObject() {
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "header", type: "string", optional: false, cl: nil),
                CoppyField(key: "cta", type: "string", optional: true, cl: nil),
                CoppyField(key: "body", type: "string", optional: false, cl: nil),
            ],
            name: "TestContent"
        )
        
        let result = try? CoppyGenerator.generateClasses(cl)
        
        let expected = """
                public class TestContent: Encodable {
                    public private(set) var header: String
                    public private(set) var cta: String?
                    public private(set) var body: String
                
                    init(
                        _ header: String,
                        _ cta: String?,
                        _ body: String
                    ) {
                        self.header = header
                        self.cta = cta
                        self.body = body
                    }
                
                    internal func update(_ v: [String: Any]) {
                        if let header = v["header"] as? String { self.header = header }
                        if let cta = v["cta"] as? String, !cta.isEmpty { self.cta = cta } else { self.cta = nil }
                        if let body = v["body"] as? String { self.body = body }
                    }
                
                    internal static func createFrom(_ _obj: [String: Any]?) -> TestContent? {
                        guard let obj = _obj else { return nil }
                        guard let header = obj["header"] as? String,
                              let body = obj["body"] as? String else { return nil }
                
                        return TestContent(
                            header,
                            obj["cta"] as? String ?? nil,
                            body
                        )
                    }
                
                    enum CodingKeys: CodingKey {
                        case header
                        case cta
                        case body
                    }
                
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(header, forKey: .header)
                        try container.encode(cta, forKey: .cta)
                        try container.encode(body, forKey: .body)
                    }
                }
                """
        XCTAssertEqual(result, expected)
    }
    
    func testGenerateClasses_WithObjectProps() {
        let bodyClass = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "string", optional: false, cl: nil),
                CoppyField(key: "title", type: "string", optional: false, cl: nil)
            ],
            name: "TestContentBody"
        )
        let linkClass = CoppyClass(
            fields: [
                CoppyField(key: "title", type: "string", optional: false, cl: nil),
                CoppyField(key: "url", type: "string", optional: true, cl: nil)
            ],
            name: "TestContentLink"
        )
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "object", optional: false, cl: bodyClass),
                CoppyField(key: "link", type: "object", optional: true, cl: linkClass),
                CoppyField(key: "title", type: "string", optional: false, cl: nil),
            ],
            name: "TestContent"
        )
        
        let result = try? CoppyGenerator.generateClasses(cl)
        
        let expected = """
                public class TestContentBody: Encodable {
                    public private(set) var body: String
                    public private(set) var title: String
                
                    init(
                        _ body: String,
                        _ title: String
                    ) {
                        self.body = body
                        self.title = title
                    }
                
                    internal func update(_ v: [String: Any]) {
                        if let body = v["body"] as? String { self.body = body }
                        if let title = v["title"] as? String { self.title = title }
                    }
                
                    internal static func createFrom(_ _obj: [String: Any]?) -> TestContentBody? {
                        guard let obj = _obj else { return nil }
                        guard let body = obj["body"] as? String,
                              let title = obj["title"] as? String else { return nil }
                
                        return TestContentBody(
                            body,
                            title
                        )
                    }
                
                    enum CodingKeys: CodingKey {
                        case body
                        case title
                    }
                
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(body, forKey: .body)
                        try container.encode(title, forKey: .title)
                    }
                }
                
                public class TestContentLink: Encodable {
                    public private(set) var title: String
                    public private(set) var url: String?
                
                    init(
                        _ title: String,
                        _ url: String?
                    ) {
                        self.title = title
                        self.url = url
                    }
                
                    internal func update(_ v: [String: Any]) {
                        if let title = v["title"] as? String { self.title = title }
                        if let url = v["url"] as? String, !url.isEmpty { self.url = url } else { self.url = nil }
                    }
                
                    internal static func createFrom(_ _obj: [String: Any]?) -> TestContentLink? {
                        guard let obj = _obj else { return nil }
                        guard let title = obj["title"] as? String else { return nil }
                
                        return TestContentLink(
                            title,
                            obj["url"] as? String ?? nil
                        )
                    }
                
                    enum CodingKeys: CodingKey {
                        case title
                        case url
                    }
                
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(title, forKey: .title)
                        try container.encode(url, forKey: .url)
                    }
                }
                
                public class TestContent: Encodable {
                    public let body: TestContentBody
                    public private(set) var link: TestContentLink?
                    public private(set) var title: String
                
                    init(
                        _ body: TestContentBody,
                        _ link: TestContentLink?,
                        _ title: String
                    ) {
                        self.body = body
                        self.link = link
                        self.title = title
                    }
                
                    internal func update(_ v: [String: Any]) {
                        if let body = v["body"] as? [String: Any] { self.body.update(body) }
                        if let link = v["link"] as? [String: Any] {
                            if self.link != nil { self.link!.update(link) }
                            else { self.link = TestContentLink.createFrom(link) }
                        } else { self.link = nil }
                        if let title = v["title"] as? String { self.title = title }
                    }
                
                    internal static func createFrom(_ _obj: [String: Any]?) -> TestContent? {
                        guard let obj = _obj else { return nil }
                        guard let body = TestContentBody.createFrom(obj["body"] as? [String: Any]),
                              let title = obj["title"] as? String else { return nil }
                
                        return TestContent(
                            body,
                            TestContentLink.createFrom(obj["link"] as? [String: Any]),
                            title
                        )
                    }
                
                    enum CodingKeys: CodingKey {
                        case body
                        case link
                        case title
                    }
                
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(body, forKey: .body)
                        try container.encode(link, forKey: .link)
                        try container.encode(title, forKey: .title)
                    }
                }
                """
        XCTAssertEqual(result, expected)
    }
    
    func testGenerateClasses_WithArrayProps() {
        let questionsClass = CoppyClass(
            fields: [
                CoppyField(key: "question", type: "string", optional: false, cl: nil),
                CoppyField(key: "title", type: "string", optional: false, cl: nil)
            ],
            name: "TestContentQuestions"
        )
        let linksClass = CoppyClass(
            fields: [
                CoppyField(key: "title", type: "string", optional: false, cl: nil),
                CoppyField(key: "url", type: "string", optional: true, cl: nil)
            ],
            name: "TestContentLinks"
        )
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "questions", type: "array", optional: false, cl: questionsClass),
                CoppyField(key: "links", type: "array", optional: true, cl: linksClass),
                CoppyField(key: "benefits", type: "array", optional: false, cl: nil),
                CoppyField(key: "title", type: "string", optional: false, cl: nil),
            ],
            name: "TestContent"
        )
        
        let result = try? CoppyGenerator.generateClasses(cl)
        
        let expected = """
                public class TestContentQuestions: Encodable {
                    public private(set) var question: String
                    public private(set) var title: String
                
                    init(
                        _ question: String,
                        _ title: String
                    ) {
                        self.question = question
                        self.title = title
                    }
                
                    internal func update(_ v: [String: Any]) {
                        if let question = v["question"] as? String { self.question = question }
                        if let title = v["title"] as? String { self.title = title }
                    }
                
                    internal static func createFrom(_ _obj: [String: Any]?) -> TestContentQuestions? {
                        guard let obj = _obj else { return nil }
                        guard let question = obj["question"] as? String,
                              let title = obj["title"] as? String else { return nil }
                
                        return TestContentQuestions(
                            question,
                            title
                        )
                    }
                
                    enum CodingKeys: CodingKey {
                        case question
                        case title
                    }
                
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(question, forKey: .question)
                        try container.encode(title, forKey: .title)
                    }
                }
                
                public class TestContentLinks: Encodable {
                    public private(set) var title: String
                    public private(set) var url: String?
                
                    init(
                        _ title: String,
                        _ url: String?
                    ) {
                        self.title = title
                        self.url = url
                    }
                
                    internal func update(_ v: [String: Any]) {
                        if let title = v["title"] as? String { self.title = title }
                        if let url = v["url"] as? String, !url.isEmpty { self.url = url } else { self.url = nil }
                    }
                
                    internal static func createFrom(_ _obj: [String: Any]?) -> TestContentLinks? {
                        guard let obj = _obj else { return nil }
                        guard let title = obj["title"] as? String else { return nil }
                
                        return TestContentLinks(
                            title,
                            obj["url"] as? String ?? nil
                        )
                    }
                
                    enum CodingKeys: CodingKey {
                        case title
                        case url
                    }
                
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(title, forKey: .title)
                        try container.encode(url, forKey: .url)
                    }
                }
                
                public class TestContent: Encodable {
                    public private(set) var questions: [TestContentQuestions]
                    public private(set) var links: [TestContentLinks]?
                    public private(set) var benefits: [String]
                    public private(set) var title: String
                
                    init(
                        _ questions: [TestContentQuestions],
                        _ links: [TestContentLinks]?,
                        _ benefits: [String],
                        _ title: String
                    ) {
                        self.questions = questions
                        self.links = links
                        self.benefits = benefits
                        self.title = title
                    }
                
                    internal func update(_ v: [String: Any]) {
                        if let questions = v["questions"] as? [[String: Any]] {
                            var questionsList: [TestContentQuestions] = []
                            for el in questions {
                                let _item = TestContentQuestions.createFrom(el)
                                if let item = _item { questionsList.append(item) }
                            }
                            self.questions = questionsList
                        }
                        if let links = v["links"] as? [[String: Any]] {
                            var linksList: [TestContentLinks] = []
                            for el in links {
                                let _item = TestContentLinks.createFrom(el)
                                if let item = _item { linksList.append(item) }
                            }
                            self.links = linksList
                        } else { self.links = nil }
                        if let benefits = v["benefits"] as? [String] {
                            self.benefits = benefits
                        }
                        if let title = v["title"] as? String { self.title = title }
                    }
                
                    internal static func createQuestionsList(_ _arr: [[String: Any]]?) -> [TestContentQuestions]? {
                        guard let arr = _arr else { return nil }
                        var result: [TestContentQuestions] = []
                        for el in arr {
                            let _item = TestContentQuestions.createFrom(el)
                            if let item = _item { result.append(item) }
                        }
                        return result
                    }
                
                    internal static func createLinksList(_ _arr: [[String: Any]]?) -> [TestContentLinks]? {
                        guard let arr = _arr else { return nil }
                        var result: [TestContentLinks] = []
                        for el in arr {
                            let _item = TestContentLinks.createFrom(el)
                            if let item = _item { result.append(item) }
                        }
                        return result
                    }
                
                    internal static func createFrom(_ _obj: [String: Any]?) -> TestContent? {
                        guard let obj = _obj else { return nil }
                        guard let questions = TestContent.createQuestionsList(obj["questions"] as? [[String: Any]]),
                              let benefits = obj["benefits"] as? [String],
                              let title = obj["title"] as? String else { return nil }
                
                        return TestContent(
                            questions,
                            TestContent.createLinksList(obj["links"] as? [[String: Any]]),
                            benefits,
                            title
                        )
                    }
                
                    enum CodingKeys: CodingKey {
                        case questions
                        case links
                        case benefits
                        case title
                    }
                
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(questions, forKey: .questions)
                        try container.encode(links, forKey: .links)
                        try container.encode(benefits, forKey: .benefits)
                        try container.encode(title, forKey: .title)
                    }
                }
                """
        XCTAssertEqual(result, expected)
    }
    
    func testGenerateContentClass() {
        let bodyQuestionsOptional = CoppyClass(fields: [
            CoppyField(key: "title", type: "string", optional: false, cl: nil),
        ], name: "TestContentBodyQuestionsOptional")
        
        let bodyQuestionsClass = CoppyClass(
            fields: [
                CoppyField(key: "question", type: "string", optional: false, cl: nil),
                CoppyField(key: "title", type: "string", optional: false, cl: nil),
                CoppyField(key: "optional", type: "object", optional: true, cl: bodyQuestionsOptional),
            ],
            name: "TestContentBodyQuestions"
        )
        let bodyHeaderClass = CoppyClass(
            fields: [
                CoppyField(key: "title", type: "string", optional: false, cl: nil),
                CoppyField(key: "body", type: "string", optional: true, cl: nil)
            ],
            name: "TestContentBodyHeader"
        )
        let bodyClass = CoppyClass(
            fields: [
                CoppyField(key: "questions", type: "array", optional: false, cl: bodyQuestionsClass),
                CoppyField(key: "header", type: "object", optional: false, cl: bodyHeaderClass)
            ],
            name: "TestContentBody"
        )
        let linksClass = CoppyClass(
            fields: [
                CoppyField(key: "title", type: "string", optional: false, cl: nil),
                CoppyField(key: "url", type: "string", optional: true, cl: nil)
            ],
            name: "TestContentLinks"
        )
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "object", optional: false, cl: bodyClass),
                CoppyField(key: "links", type: "array", optional: true, cl: linksClass),
                CoppyField(key: "benefits", type: "array", optional: false, cl: nil),
                CoppyField(key: "title", type: "string", optional: true, cl: nil),
            ],
            name: "TestContent"
        )
        let content: [String: Any] = [
            "body": [
                "questions": [
                    [ "question": "Question One", "title": "Question title one" ],
                    [ "question": "Question Two", "title": "Question title Two" ]
                ],
                "header": [ "title": "Body\r\rtitle" ]
            ],
            "benefits": ["Benefit One", "Benefit Two"],
            "title": """
                Title
                
                Seconf line.
                """
        ]
        
        let result = try? CoppyGenerator.generateContentClass(cl, content)
        
        let expected = """
            public class TestContentBodyQuestionsOptional: Encodable {
                public private(set) var title: String
            
                init(
                    _ title: String
                ) {
                    self.title = title
                }
            
                internal func update(_ v: [String: Any]) {
                    if let title = v["title"] as? String { self.title = title }
                }
            
                internal static func createFrom(_ _obj: [String: Any]?) -> TestContentBodyQuestionsOptional? {
                    guard let obj = _obj else { return nil }
                    guard let title = obj["title"] as? String else { return nil }
            
                    return TestContentBodyQuestionsOptional(
                        title
                    )
                }
            
                enum CodingKeys: CodingKey {
                    case title
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(title, forKey: .title)
                }
            }
            
            public class TestContentBodyQuestions: Encodable {
                public private(set) var question: String
                public private(set) var title: String
                public private(set) var optional: TestContentBodyQuestionsOptional?
            
                init(
                    _ question: String,
                    _ title: String,
                    _ optional: TestContentBodyQuestionsOptional?
                ) {
                    self.question = question
                    self.title = title
                    self.optional = optional
                }
            
                internal func update(_ v: [String: Any]) {
                    if let question = v["question"] as? String { self.question = question }
                    if let title = v["title"] as? String { self.title = title }
                    if let optional = v["optional"] as? [String: Any] {
                        if self.optional != nil { self.optional!.update(optional) }
                        else { self.optional = TestContentBodyQuestionsOptional.createFrom(optional) }
                    } else { self.optional = nil }
                }
            
                internal static func createFrom(_ _obj: [String: Any]?) -> TestContentBodyQuestions? {
                    guard let obj = _obj else { return nil }
                    guard let question = obj["question"] as? String,
                          let title = obj["title"] as? String else { return nil }
            
                    return TestContentBodyQuestions(
                        question,
                        title,
                        TestContentBodyQuestionsOptional.createFrom(obj["optional"] as? [String: Any])
                    )
                }
            
                enum CodingKeys: CodingKey {
                    case question
                    case title
                    case optional
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(question, forKey: .question)
                    try container.encode(title, forKey: .title)
                    try container.encode(optional, forKey: .optional)
                }
            }
            
            public class TestContentBodyHeader: Encodable {
                public private(set) var title: String
                public private(set) var body: String?
            
                init(
                    _ title: String,
                    _ body: String?
                ) {
                    self.title = title
                    self.body = body
                }
            
                internal func update(_ v: [String: Any]) {
                    if let title = v["title"] as? String { self.title = title }
                    if let body = v["body"] as? String, !body.isEmpty { self.body = body } else { self.body = nil }
                }
            
                internal static func createFrom(_ _obj: [String: Any]?) -> TestContentBodyHeader? {
                    guard let obj = _obj else { return nil }
                    guard let title = obj["title"] as? String else { return nil }
            
                    return TestContentBodyHeader(
                        title,
                        obj["body"] as? String ?? nil
                    )
                }
            
                enum CodingKeys: CodingKey {
                    case title
                    case body
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(title, forKey: .title)
                    try container.encode(body, forKey: .body)
                }
            }
            
            public class TestContentBody: Encodable {
                public private(set) var questions: [TestContentBodyQuestions]
                public let header: TestContentBodyHeader
            
                init(
                    _ questions: [TestContentBodyQuestions],
                    _ header: TestContentBodyHeader
                ) {
                    self.questions = questions
                    self.header = header
                }
            
                internal func update(_ v: [String: Any]) {
                    if let questions = v["questions"] as? [[String: Any]] {
                        var questionsList: [TestContentBodyQuestions] = []
                        for el in questions {
                            let _item = TestContentBodyQuestions.createFrom(el)
                            if let item = _item { questionsList.append(item) }
                        }
                        self.questions = questionsList
                    }
                    if let header = v["header"] as? [String: Any] { self.header.update(header) }
                }
            
                internal static func createQuestionsList(_ _arr: [[String: Any]]?) -> [TestContentBodyQuestions]? {
                    guard let arr = _arr else { return nil }
                    var result: [TestContentBodyQuestions] = []
                    for el in arr {
                        let _item = TestContentBodyQuestions.createFrom(el)
                        if let item = _item { result.append(item) }
                    }
                    return result
                }
            
                internal static func createFrom(_ _obj: [String: Any]?) -> TestContentBody? {
                    guard let obj = _obj else { return nil }
                    guard let questions = TestContentBody.createQuestionsList(obj["questions"] as? [[String: Any]]),
                          let header = TestContentBodyHeader.createFrom(obj["header"] as? [String: Any]) else { return nil }
            
                    return TestContentBody(
                        questions,
                        header
                    )
                }
            
                enum CodingKeys: CodingKey {
                    case questions
                    case header
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(questions, forKey: .questions)
                    try container.encode(header, forKey: .header)
                }
            }
            
            public class TestContentLinks: Encodable {
                public private(set) var title: String
                public private(set) var url: String?
            
                init(
                    _ title: String,
                    _ url: String?
                ) {
                    self.title = title
                    self.url = url
                }
            
                internal func update(_ v: [String: Any]) {
                    if let title = v["title"] as? String { self.title = title }
                    if let url = v["url"] as? String, !url.isEmpty { self.url = url } else { self.url = nil }
                }
            
                internal static func createFrom(_ _obj: [String: Any]?) -> TestContentLinks? {
                    guard let obj = _obj else { return nil }
                    guard let title = obj["title"] as? String else { return nil }
            
                    return TestContentLinks(
                        title,
                        obj["url"] as? String ?? nil
                    )
                }
            
                enum CodingKeys: CodingKey {
                    case title
                    case url
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(title, forKey: .title)
                    try container.encode(url, forKey: .url)
                }
            }
            
            final public class TestContent: CoppyUpdatable {
                @Published public private(set) var body: TestContentBody
                @Published public private(set) var links: [TestContentLinks]?
                @Published public private(set) var benefits: [String]
                @Published public private(set) var title: String?
            
                public init() {
                    self.body = TestContentBody(
                        [
                            TestContentBodyQuestions(
                                #######\"\"\"
                                    Question One
                                    \"\"\"#######,
                                #######\"\"\"
                                    Question title one
                                    \"\"\"#######,
                                nil
                            ),
                            TestContentBodyQuestions(
                                #######\"\"\"
                                    Question Two
                                    \"\"\"#######,
                                #######\"\"\"
                                    Question title Two
                                    \"\"\"#######,
                                nil
                            )
                        ],
                        TestContentBodyHeader(
                            #######\"\"\"
                                Body
                                
                                title
                                \"\"\"#######,
                            nil
                        )
                    )
                    self.links = nil
                    self.benefits = [
                        #######\"\"\"
                            Benefit One
                            \"\"\"#######,
                        #######\"\"\"
                            Benefit Two
                            \"\"\"#######
                    ]
                    self.title = #######\"\"\"
                        Title
                        
                        Seconf line.
                        \"\"\"#######
                }
            
                public func update(_ v: [String: Any]) {
                    var willUpdate: Bool = false
                    if let body = v["body"] as? [String: Any] { self.body.update(body); willUpdate = true }
                    if let links = v["links"] as? [[String: Any]] {
                        var linksList: [TestContentLinks] = []
                        for el in links {
                            let _item = TestContentLinks.createFrom(el)
                            if let item = _item { linksList.append(item) }
                        }
                        self.links = linksList
                        willUpdate = true
                    } else { self.links = nil; willUpdate = true }
                    if let benefits = v["benefits"] as? [String] {
                        self.benefits = benefits
                        willUpdate = true
                    }
                    if let title = v["title"] as? String, !title.isEmpty { self.title = title; willUpdate = true } else { self.title = nil; willUpdate = true }
                    if willUpdate { self.objectWillChange.send() }
                }
            
                enum CodingKeys: CodingKey {
                    case body
                    case links
                    case benefits
                    case title
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(body, forKey: .body)
                    try container.encode(links, forKey: .links)
                    try container.encode(benefits, forKey: .benefits)
                    try container.encode(title, forKey: .title)
                }
            }
            """

        XCTAssertEqual(result, expected)
    }
    
    func testGenerateContentClass_throwsIfRequiredStringFieldIsMissing() {
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "string", optional: true, cl: nil),
                CoppyField(key: "title", type: "string", optional: false, cl: nil),
            ],
            name: "TestContent"
        )
        let content = ["body": "Body"]
        
        var thrownError: Error?
        
        XCTAssertThrowsError(try CoppyGenerator.generateContentClass(cl, content)) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError.debugDescription.contains("Missing value for not optional field title"))
    }
    
    func testGenerateContentClass_throwsIfRequiredObjectFieldIsMissing() {
        let bodyclass = CoppyClass(fields: [
            CoppyField(key: "title", type: "string", optional: false, cl: nil),
        ], name: "TestContentBody")
        
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "object", optional: false, cl: bodyclass),
                CoppyField(key: "title", type: "string", optional: true, cl: nil),
            ],
            name: "TestContent"
        )
        let content = ["title": "title"]
        
        var thrownError: Error?
        
        XCTAssertThrowsError(try CoppyGenerator.generateContentClass(cl, content)) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError.debugDescription.contains("Missing value for not optional field body"))
    }
    
    func testGenerateContentClass_throwsIfClassIsMissingForObjectField() {
        
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "object", optional: false, cl: nil),
                CoppyField(key: "title", type: "string", optional: true, cl: nil),
            ],
            name: "TestContent"
        )
        let content: [String: Any] = ["title": "title", "body": ["title": "Body title"]]
        
        var thrownError: Error?
        
        XCTAssertThrowsError(try CoppyGenerator.generateContentClass(cl, content)) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError.debugDescription.contains("Missing class definition for object field body"))
    }
    
    func testGenerateContentClass_throwsIfIncorrectValuePassedToObjectField() {
        let bodyclass = CoppyClass(fields: [
            CoppyField(key: "title", type: "string", optional: false, cl: nil),
        ], name: "TestContentBody")
        
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "object", optional: false, cl: bodyclass),
                CoppyField(key: "title", type: "string", optional: true, cl: nil),
            ],
            name: "TestContent"
        )
        let content: [String: Any] = ["title": "title", "body": "body"]
        
        var thrownError: Error?
        
        XCTAssertThrowsError(try CoppyGenerator.generateContentClass(cl, content)) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError.debugDescription.contains("Incorrect value passed for the object field body: body"))
    }
    
    func testGenerateContentClass_throwsIfIncorrectValuePassedToStringField() {
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "string", optional: false, cl: nil),
                CoppyField(key: "title", type: "string", optional: true, cl: nil),
            ],
            name: "TestContent"
        )
        let content: [String: Any] = ["title": "title", "body": ["body": "Body"]]
        
        var thrownError: Error?
        
        XCTAssertThrowsError(try CoppyGenerator.generateContentClass(cl, content)) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError.debugDescription.contains(#"Incorrect value passed for the string field body: [\"body\": \"Body\"]"#))
    }
    
    func testGenerateContentClass_throwsIfIncorrectValuePassedToArrayStringField() {
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "array", optional: false, cl: nil),
                CoppyField(key: "title", type: "string", optional: true, cl: nil),
            ],
            name: "TestContent"
        )
        let content: [String: Any] = ["title": "title", "body": "body"]
        
        var thrownError: Error?
        
        XCTAssertThrowsError(try CoppyGenerator.generateContentClass(cl, content)) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError.debugDescription.contains("Incorrect value passed for the strings list field body: body"))
    }
    
    func testGenerateContentClass_throwsIfIncorrectValuePassedToArrayObjectsField() {
        let bodyclass = CoppyClass(fields: [
            CoppyField(key: "title", type: "string", optional: false, cl: nil),
        ], name: "TestContentBody")
        
        let cl = CoppyClass(
            fields: [
                CoppyField(key: "body", type: "array", optional: false, cl: bodyclass),
                CoppyField(key: "title", type: "string", optional: true, cl: nil),
            ],
            name: "TestContent"
        )
        let content: [String: Any] = ["title": "title", "body": ["body"]]
        
        var thrownError: Error?
        
        XCTAssertThrowsError(try CoppyGenerator.generateContentClass(cl, content)) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError.debugDescription.contains(#"Incorrect value passed for the objects list field body: [\"body\"]"#))
    }
    
    func testGenerateContentFile_generatesContent() {
        let content: [String: Any] = [
            "body": [
                "header": [ "body": "" ]
            ]
        ]
        
        let result = try? CoppyGenerator.generateContentFile(content, classPrefix: "Prefix")
        
        let expected = """
            import Foundation
            import Coppy
            
            public class PrefixCoppyContentBodyHeader: Encodable {
                public private(set) var body: String?
            
                init(
                    _ body: String?
                ) {
                    self.body = body
                }
            
                internal func update(_ v: [String: Any]) {
                    if let body = v["body"] as? String, !body.isEmpty { self.body = body } else { self.body = nil }
                }
            
                internal static func createFrom(_ _obj: [String: Any]?) -> PrefixCoppyContentBodyHeader? {
                    guard let obj = _obj else { return nil }
            
                    return PrefixCoppyContentBodyHeader(
                        obj["body"] as? String ?? nil
                    )
                }
            
                enum CodingKeys: CodingKey {
                    case body
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(body, forKey: .body)
                }
            }
            
            public class PrefixCoppyContentBody: Encodable {
                public let header: PrefixCoppyContentBodyHeader
            
                init(
                    _ header: PrefixCoppyContentBodyHeader
                ) {
                    self.header = header
                }
            
                internal func update(_ v: [String: Any]) {
                    if let header = v["header"] as? [String: Any] { self.header.update(header) }
                }
            
                internal static func createFrom(_ _obj: [String: Any]?) -> PrefixCoppyContentBody? {
                    guard let obj = _obj else { return nil }
                    guard let header = PrefixCoppyContentBodyHeader.createFrom(obj["header"] as? [String: Any]) else { return nil }
            
                    return PrefixCoppyContentBody(
                        header
                    )
                }
            
                enum CodingKeys: CodingKey {
                    case header
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(header, forKey: .header)
                }
            }
            
            final public class PrefixCoppyContent: CoppyUpdatable {
                @Published public private(set) var body: PrefixCoppyContentBody
            
                public init() {
                    self.body = PrefixCoppyContentBody(
                        PrefixCoppyContentBodyHeader(
                            nil
                        )
                    )
                }
            
                public func update(_ v: [String: Any]) {
                    var willUpdate: Bool = false
                    if let body = v["body"] as? [String: Any] { self.body.update(body); willUpdate = true }
                    if willUpdate { self.objectWillChange.send() }
                }
            
                enum CodingKeys: CodingKey {
                    case body
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(body, forKey: .body)
                }
            }
            """
        
        XCTAssertEqual(result, expected)
    }
}
