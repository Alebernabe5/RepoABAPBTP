using {sap.capire.incidents as my} from '../db/schema';

/** * Service used by support personell, i.e. the incidents' 'processors'. */
service ProcessorService {
    entity Incidents as projection on my.Incidents;
    // No pongas nada de Customers aquí, deja que remote.cds lo inyecte
}

/** * Service used by administrators to manage customers and incidents. */
service AdminService {
    entity Customers as projection on my.Customers;
    entity Incidents as projection on my.Incidents;
}

// Anotaciones fuera de los bloques de servicio
annotate ProcessorService.Incidents with @odata.draft.enabled;
annotate ProcessorService with @(requires: 'support');
annotate AdminService with @(requires: 'admin');