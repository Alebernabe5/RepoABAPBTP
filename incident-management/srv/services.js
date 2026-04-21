const cds = require('@sap/cds');

class ProcessorService extends cds.ApplicationService {
  /** Registering custom event handlers */
  async init() {
    this.before("UPDATE", "Incidents", (req) => this.onUpdate(req));
    this.before("CREATE", "Incidents", (req) => this.changeUrgencyDueToSubject(req));

    // Conexión a la API Externa de SAP S/4HANA
    try {
      this.S4bupa = await cds.connect.to('API_BUSINESS_PARTNER');
    } catch (err) {
      console.warn('El destino API_BUSINESS_PARTNER no está configurado. Usando mock local.');
    }

    // Interceptar llamadas READ de Clientes y redirigirlas a S/4HANA
    this.on('READ', 'Customers', (req) => this.onCustomerRead(req));
    
    // Cachear los datos del cliente al crear o modificar un incidente
    this.on(['CREATE', 'UPDATE'], 'Incidents', (req, next) => this.onCustomerCache(req, next));

    return super.init();
  }

  changeUrgencyDueToSubject(req) {
    if (req.data.title?.toLowerCase().includes("urgent")) {
      req.data.urgency_code = "H";
    }
  }

  async onUpdate(req) {
    const { status_code } = await SELECT.one(req.subject, i => i.status_code).where({ID: req.data.ID});
    if (status_code === 'C') {
      return req.reject(400, `Can't modify a closed incident`);
    }
  }

  async onCustomerRead(req) {
    console.log('>> Delegando lectura a S/4HANA...', req.query);
    const top = parseInt(req._queryOptions?.$top) || 100;
    const skip = parseInt(req._queryOptions?.$skip) || 0;

    const { Customers } = this.entities;

    // Ejecutar petición hacia S/4HANA y devolver el resultado
    let result = await this.S4bupa.run(SELECT.from(Customers).limit(top, skip));
    result.$count = 1000;
    return result;
  }

  async onCustomerCache(req, next) {
    const { Customers } = this.entities;
    const newCustomerId = req.data.customer_ID;
    
    // Continuar con la creación/actualización del incidente primero
    const result = await next();
    
    if (newCustomerId && (req.event === "CREATE" || req.event === "UPDATE")) {
      console.log('>> Buscando cliente en S/4HANA para caché local...');
      const customer = await this.S4bupa.run(SELECT.one(Customers).where({ ID: newCustomerId }));
      
      if (customer) {
        // Guardar/Actualizar el cliente en nuestra DB local para accesos rápidos futuros
        await UPSERT.into(Customers).entries(customer);
      }
    }
    return result;
  }
}

module.exports = { ProcessorService };
