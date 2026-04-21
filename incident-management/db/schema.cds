using {
    cuid,
    managed
} from '@sap/cds/common';
using {sap.common.CodeList} from '@sap/cds/common';

namespace sap.capire.incidents; /**  * Entidades Principales  */

entity Incidents : cuid, managed {
    customer     : Association to Customers;
    title        : String;
    urgency      : Association to Urgency;
    status       : Association to Status;
    conversation : Composition of many {
                       key ID        : UUID;
                           timestamp : DateTime @cds.on.insert: $now;
                           author    : String   @cds.on.insert: $user;
                           message   : String;
                   };
}

entity Customers : managed {
    key ID        : String;
        firstName : String;
        lastName  : String;
        email     : EMailAddress;
        phone     : PhoneNumber;
        incidents : Association to many Incidents
                        on incidents.customer = $self;
        addresses : Composition of many Addresses
                        on addresses.customer = $self;
}

entity Addresses : cuid, managed {
    customer      : Association to Customers;
    city          : String;
    postCode      : String;
    streetAddress : String;
} /**  * Listas Desplegables (CodeLists)  */

entity Status : CodeList {
    key code        : String enum {
            new = 'N';
            assigned = 'A';
            in_process = 'I';
            on_hold = 'H';
            resolved = 'R';
            closed = 'C';
        };
        criticality : Integer;
}

entity Urgency : CodeList {
    key code : String enum {
            high = 'H';
            medium = 'M';
            low = 'L';
        };
} /**  * Tipos Personalizados  */

type EMailAddress : String;
type PhoneNumber  : String;
