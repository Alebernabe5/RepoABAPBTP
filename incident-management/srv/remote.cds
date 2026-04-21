using { API_BUSINESS_PARTNER as external } from './external/API_BUSINESS_PARTNER';
using { ProcessorService } from './services'; 



// PASO B: Extender el servicio con la entidad externa
extend service ProcessorService with {
    @readonly
    entity Customers as projection on external.A_BusinessPartner {
        key BusinessPartner as ID,
        FirstName as firstName,
        LastName as lastName,
        BusinessPartnerName as name,
        to_BusinessPartnerAddress as addresses
    }
}