include "console.iol"
include "sla.iol"
include "../calculator/calculator.iol"
include "time.iol"
include "../config.iol"

execution { concurrent }

// Service Level Agreements can be stated in the constants and be overriden when powering the service
constants {
    SERVICE_LEVEL_OBJECTIVE_RESPONSE_TIME = 2,
    SERVICE_LEVEL_OBJECTIVE_AVG_RESPONSE_TIME = 15,
    SERVICE_LEVEL_OBJECTIVE_NUMBER_OF_BREACH_RESPONSE_TIMES = 5
}

outputPort Calculator {Interfaces: CalculatorInterface}
embedded {Jolie: "../Calculator/calculator.ol" in Calculator}

inputPort SLA {
    Location: ServiceLevelAgreement_Location
    Protocol: http { .statusCode -> statusCode, .format = "json"}
    Interfaces: ServiceLevelInterface
    Aggregates: Calculator with ServiceLevelInterface_extender // Important: has to be of same interface type
}

//outputPort SLA {
//    Location: ServiceLevelAgreement_Location
//    Protocol: http { .statusCode -> statusCode, .format = json}
//    Interfaces: ServiceLevelInterface
//}

define calculateTheAvgFailedResponseTime {
    global.total_responsetimes = global.total_responsetimes + objectives.responsetime;
    sum = global.total_responsetimes / global.number_of_requests
}

define sla_reporting {
    objectives.responsetime = double(stop - start);
    calculateTheAvgFailedResponseTime;
    objectives.avgresponsetime = sum;
    objectives.breaches = global.number_of_breaches;
    
    if ( objectives.responsetime > SERVICE_LEVEL_OBJECTIVE_RESPONSE_TIME ) {
        global.number_of_breaches++
        if ( global.number_of_breaches >= SERVICE_LEVEL_OBJECTIVE_NUMBER_OF_BREACH_RESPONSE_TIMES ) {
            println@Console("It is time to pay a penalty!")()    
        }
        println@Console( "Service Level Objective (Response Time) of " + SERVICE_LEVEL_OBJECTIVE_RESPONSE_TIME + " has been breached!" )()
    } else {
        if(sum < SERVICE_LEVEL_OBJECTIVE_AVG_RESPONSE_TIME) {
            println@Console( "Service Level Objective (Response Time) of " + SERVICE_LEVEL_OBJECTIVE_RESPONSE_TIME + " did not breach!" )()
            println@Console( "Service Level Objective (Avg Response Time) of " + SERVICE_LEVEL_OBJECTIVE_AVG_RESPONSE_TIME + " did not breach!" )()
        }
        println@Console( "Service Level Objective (Avg Response Time) of " + SERVICE_LEVEL_OBJECTIVE_AVG_RESPONSE_TIME + " did breach!" )()   
    }
    with( response ) { .servicelevelagreement.objectives << objectives };
    undef ( objectives )
}

courier SLA {
    [calculator( request )( response ) ] {
        global.number_of_requests++; // Keeping track of every request
        getCurrentTimeMillis@Time(void)(start);
        forward( request )( response );
        getCurrentTimeMillis@Time(void)(stop);
        sla_reporting // A function
    } 
}

init
{
	println@Console( "SLA Middleware Service started" )();
	install( Aborted => nullProcess );
    global.number_of_breaches = 0;
    global.number_of_requests = 0
}

main {
    
    [slareporting( void )( response ) {
        isTheAvgFailedResponseTimesOK;
        
        response.servicelevelagreement.objectives.avgresponsetime = sum;
        response.servicelevelagreement.objectives.breaches = global.number_of_breaches
    }]
}