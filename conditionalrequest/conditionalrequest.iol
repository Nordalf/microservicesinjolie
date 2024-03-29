type CondReqRequestType: void {
    ."If-Modified-Since"?: string
}
type CondReqResponseType: void{
    .msg?: string
    .statusCode: int
}

interface extender ConditionalRequestInterface_Extender {
    RequestResponse: *( CondReqRequestType )( CondReqResponseType ) throws NoResponse ( string )
}

interface ConditionalRequestInterface {
    OneWay:
        conditionalrequest( CondReqResponseType )
}