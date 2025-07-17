package dnsmsg

// Type is the type of a DNS query.
public type Type = UInt16
// Resource Record (RR) and Question types
public const TypeA: Type = 1 // a host address
public const TypeNS: Type = 2 // an authoritative name server
public const TypeCNAME: Type = 5 // the canonical name for an alias
public const TypeSOA: Type = 6 // marks the start of a zone of authority
public const TypeWKS: Type = 11 // a well known service description
public const TypePTR: Type = 12 // a domain name pointer
public const TypeHINFO: Type = 13 // host information
public const TypeMINFO: Type = 14 // mailbox or mail list information
public const TypeMX: Type = 15 // mail exchange
public const TypeTXT: Type = 16 // text strings
public const TypeAAAA: Type = 28 // a host address (IPv6)
public const TypeSRV: Type = 33 // service locator
public const TypeOPT: Type = 41 // a pseudo-RR used to carry extended information in DNS messages

// Question types
public const TypeAXFR: Type = 252 // A request for a transfer of an entire zone
public const TypeMAILB: Type = 253 // A request for mailbox-related records (MB, MG or MR)
public const TypeMAILA: Type = 254 // A request for mail agent RRs (Obsolete - used only for examples in RFCs)
public const TypeANY: Type = 255 // A request for all records

public func getTypeName(_type: Type): String {
    if (_type == TypeA) {
        "A"
    } else if (_type == TypeNS) {
        "NS"
    } else if (_type == TypeCNAME) {
        "CNAME"
    } else if (_type == TypeSOA) {
        "SOA"
    } else if (_type == TypeWKS) {  
        "WKS"
    } else if (_type == TypePTR) {
        "PTR"
    } else if (_type == TypeHINFO) {
        "HINFO"
    } else if (_type == TypeMINFO) {
        "MINFO"
    } else if (_type == TypeMX) {
        "MX"
    } else if (_type == TypeTXT) {
        "TXT"
    } else if (_type == TypeAAAA) {
        "AAAA"
    } else if (_type == TypeSRV) {
        "SRV"
    } else if (_type == TypeOPT) {
        "OPT"
    } else if (_type == TypeAXFR) {
        "AXFR"
    } else if (_type == TypeMAILB) {
        "MAILB"
    } else if (_type == TypeMAILA) {
        "MAILA"
    } else if (_type == TypeANY) {
        "ANY"
    } else {
        throw Exception("Unknown type: ${_type}")
    }
}

// Class is the class of a DNS query.
public type Class = UInt16
// Resource Record (RR) and Question classes
public const ClassIN: Class = 1 // Internet
public const ClassCS: Class = 2 // CSNET
public const ClassCH: Class = 3 // CHAOS
public const ClassHS: Class = 4 // Hesiod
// Question classes
public const ClassNONE: Class = 254 // None
public const ClassANY: Class = 255 // Any

public func getClassName(_class: Class): String {
    if (_class == ClassIN) {
        "IN"
    } else if (_class == ClassCS) {
        "CS"
    } else if (_class == ClassCH) {
        "CH"
    } else if (_class == ClassHS) {
        "HS"
    } else if (_class == ClassNONE) {
        "NONE"
    } else if (_class == ClassANY) {
        "ANY"
    } else {
        throw Exception("Unknown class: ${_class}")
    }
}