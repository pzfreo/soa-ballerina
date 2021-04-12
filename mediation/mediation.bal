import ballerina/http;

type Ping record {
    string name;
};

type Payment record {
    string cardNumber;
    string postcode;
    string name;
    int month;
    int year;
    int cvc;
    string merchant;
    string reference;
    float amount;
};

configurable string host = "http://localhost:8000";

service / on new http:Listener(8080) {    
    resource function get hello() returns string {
        return "hello world";
    }

    resource function post ping(@http:Payload Ping p) returns json|error {        
        xmlns "http://freo.me/payment/" as pay;
        xml body = xml `<pay:ping>
                <pay:in>${<@untainted>p.name}</pay:in>
            </pay:ping>`;

        xmlns "http://schemas.xmlsoap.org/soap/envelope/" as s;
        xml soap = xml `<s:Envelope><s:Body>${body}</s:Body></s:Envelope>`;
        
        http:Client c = check new (host);

        var response = check c->post("/pay/services/paymentSOAP", soap);
        xml x = check response.getXmlPayload();
        string pingresponse = (x/**/<pay:out>/*).text().toString();
        return {
            pingResponse: pingresponse
        };
    }

    resource function post authorise(@http:Payload Payment p) returns json|error {
        
        xmlns "http://freo.me/payment/" as pay;
        xml body = xml `<pay:authorise>
            <pay:card>
                <pay:cardnumber>${p.cardNumber}</pay:cardnumber>
                <pay:postcode>${p.postcode}</pay:postcode>
                <pay:name>${p.name}</pay:name>
                <pay:expiryMonth>${p.month}</pay:expiryMonth>
                <pay:expiryYear>${p.year}</pay:expiryYear>
                <pay:cvc>${p.cvc}</pay:cvc>
            </pay:card>
            <pay:merchant>${p.merchant}</pay:merchant>
            <pay:reference>${p.reference}</pay:reference>
            <pay:amount>${p.amount}</pay:amount>
        </pay:authorise>`;

        xmlns "http://schemas.xmlsoap.org/soap/envelope/" as s;
        xml soap = xml `<s:Envelope><s:Body>${body}</s:Body></s:Envelope>`;
        
        http:Client c = check new (host);

        var response = check c->post("/pay/services/paymentSOAP", soap);
        xml x = check response.getXmlPayload();
        string authcode = (x/**/<pay:authcode>/*).text().toString();
        string reference = (x/**/<pay:reference>/*).text().toString();
        string reason = (x/**/<pay:refusalreason>/*).text().toString();
        return {
            authcode: authcode,
            reference: reference,
            refusalreason: reason
        };
    }
}