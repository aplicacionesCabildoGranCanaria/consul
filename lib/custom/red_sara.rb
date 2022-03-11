include DocumentParser

module RedSara
  require "securerandom"
  require "openssl"

  class RedSaraResponse
    def initialize(body, valid_code, invalid_id_code, data)
      @body = body
      @valid_code = valid_code
      @invalid_id_code = invalid_id_code
      @date_of_birth = data[:date_of_birth]
      @postal_code = data[:postal_code]
    end

    def valid?
      get_response_status == "0003" && get_transmission_status == @valid_code
    end

    def invalid_id?
      get_response_status == @invalid_id_code
    end

    def date_of_birth
      @date_of_birth
    end

    def postal_code
      @postal_code
    end

    def district_code
      nil
    end

    def gender
      nil
    end

    def name
      nil
    end

    private

      def get_response_status
        return false unless @body != nil

        if @body[:respuesta]
          @body[:respuesta][:atributos][:estado][:codigo_estado].strip
        else
          @body[:fault][:detail][:atributos][:estado][:codigo_estado].strip
        end
      end

      def get_transmission_status
        @body[:respuesta][:transmisiones][:transmision_datos][:datos_especificos][:retorno][:estado][:codigo_estado].strip
      end
  end

  class RedSaraApi
    def call(document_type, document_number, data)
      variant = get_document_number_variants(document_type, document_number).last
      response = RedSaraResponse.new(get_response_body(document_type, variant, data), valid_code, invalid_id_code, data)
      if response != nil
        retries = 0
        while response.invalid_id? && retries < 5
          if retries > 0
            sleep(1.0)
          end
          response = RedSaraResponse.new(get_response_body(document_type, variant, data), valid_code, invalid_id_code, data)
          if response == nil
            break
          end
          retries += 1
        end
        if response != nil && response.invalid_id?
          raise "El identificador de la petición a Red Sara ya fue utilizado"
        end
      end

      response
    end

    private

      def valid_code
        raise "Not implemented"
      end

      def invalid_id_code
        raise "Not implemented"
      end

      def get_response_body(document_type, document_number, data)
        if procedure_code_available?
          response = nil
          retries = 0
          while retries < 5
            if retries > 0
              sleep(1.0)
            end

            begin
              response = client.call(
                  "pet:Peticion",
                  message: request(document_type, document_number, data)
              ).body
              break
            rescue => e
              Rails.logger.fatal "Edosoft Red Sara: Error connected to Red Sara (retries: 1):  #{e}"
              retries += 1
            end
          end
          response
        else
          stubbed_response(document_type, document_number)
        end
      end

      def client
        nspaces = {
            'xmlns:xsd' => "http://www.w3.org/2001/XMLSchema",
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
            'xmlns:pet' => "http://intermediacion.redsara.es/scsp/esquemas/V3/peticion",
            'xmlns:env' => "http://schemas.xmlsoap.org/soap/envelope/",
            'xmlns:ns1' => "http://intermediacion.redsara.es/scsp/esquemas/datosespecificos"
        }

        pkcs = OpenSSL::PKCS12.new(
            File.read(Rails.application.secrets.red_sara_cert),
            Rails.application.secrets.red_sara_cert_password
        )
        @client = Savon.client(
            endpoint: get_endpoint,
            namespace: get_namespace,
            raise_errors: false,
            env_namespace: 'soapenv',
            namespace_identifier: nil,
            convert_request_keys_to: :none,
            ssl_verify_mode: :none,
            log_level: :debug,
            log: true,
            pretty_print_xml: true,
            follow_redirects: true,
            namespaces: nspaces,
            wsse_signature: Akami::WSSE::Signature.new(
                Akami::WSSE::Certs.new(
                    cert_string:            pkcs.certificate.to_pem.to_s,
                    private_key_string:     pkcs.key.to_pem.to_s,
                    )
            )
        )
      end

      def generate_id
        raise "Not implemented"
      end

      def get_endpoint
        raise "Not implemented"
      end

      def get_namespace
        if Rails.env.production?
          "http://intermediacion.redsara.es/scsp/wsdl"
        else
          "http://intermediacionpp.redsara.es/scsp/wsdl"
        end
      end

      def request(document_type, document_number, data)
        raise "Not implemented"
      end

      def procedure_code_defined?
        raise "Not implemented"
      end

      def procedure_code_available?
        (Rails.env.staging? || Rails.env.preproduction? || Rails.env.production?) && procedure_code_defined?
      end

      def get_document_type(document_type)
        if document_type == "1"
          "DNI"
        elsif document_type == "2"
          "Pasaporte"
        else
          "NIE"
        end
      end

      def stubbed_response(document_type, document_number)
        if (document_number == "12345678Z" || document_number == "12345678Y") && document_type == "1"
          stubbed_valid_response
        else
          stubbed_invalid_response
        end
      end

      def stubbed_valid_response
        {
            respuesta: {
                atributos: {
                    estado: {
                        codigo_estado: "0003"
                    }
                },
                transmisiones: {
                    transmision_datos: {
                        datos_especificos: {
                            retorno: {
                                estado: {
                                    codigo_estado: valid_code
                                }
                            }
                        }
                    }
                }
            }
        }
      end

      def stubbed_invalid_response
        {
            respuesta: {
                atributos: {
                    estado: {
                        codigo_estado: "0003"
                    }
                },
                transmisiones: {
                    transmision_datos: {
                        datos_especificos: {
                            retorno: {
                                estado: {
                                    codigo_estado: "ERROR"
                                }
                            }
                        }
                    }
                }
            }
        }
      end
  end

  class RedSaraValidateIdentityService < RedSaraApi

    private

      def valid_code
        "00"
      end

      def invalid_id_code
        "0229"
      end

      def generate_id
        Rails.application.secrets.red_sara_organization_id + "_I_" + Time.now.strftime("%Y%m%d") + "_" + SecureRandom.alphanumeric(5)
      end

      def get_endpoint
        if Rails.env.production?
          "https://intermediacion.redsara.es/servicios/SVD/DGP.VerificacionIdentidad"
        else
          "https://intermediacionpp.redsara.es/servicios/SVD/DGP.VerificacionIdentidad"
        end
      end

      def request(document_type, document_number, data)
        request_id = generate_id

        {
            "pet:Atributos": {
                "pet:IdPeticion": request_id,
                "pet:CodigoCertificado": "SVDDGPVIWS02",
                "pet:NumElementos": 1,
                "pet:TimeStamp": Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L%:z"),
            },
            "pet:Solicitudes": {
                "pet:SolicitudTransmision": {
                    "pet:DatosGenericos": {
                        "pet:Emisor": {
                            "pet:NifEmisor": "S2816015H",
                            "pet:NombreEmisor": "Dirección General de la Policía"
                        },
                        "pet:Solicitante": {
                            "pet:IdentificadorSolicitante": Rails.application.secrets.red_sara_organization_id,
                            "pet:NombreSolicitante": Rails.application.secrets.red_sara_organization_name,
                            "pet:Procedimiento": {
                                "pet:CodProcedimiento": Rails.application.secrets.red_sara_dgp_procedure_code,
                                "pet:NombreProcedimiento": Rails.application.secrets.red_sara_dgp_procedure_name
                            },
                            "pet:Finalidad": "VERIFICACION IDENTIDAD EN CONSUL",
                            "pet:Consentimiento": "Si",
                        },
                        "pet:Titular": {
                            "pet:TipoDocumentacion": get_document_type(document_type),
                            "pet:Documentacion": document_number,
                        },
                        "pet:Transmision": {
                            "pet:CodigoCertificado": "SVDDGPVIWS02",
                            "pet:IdSolicitud": request_id,
                            "pet:FechaGeneracion": Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L%:z")
                        }
                    },
                    "ns1:DatosEspecificos": {
                        "ns1:Consulta": {
                            "ns1:DatosNacimiento": {
                                "ns1:Fecha": data[:date_of_birth].strftime("%Y%m%d")
                            }
                        }
                    }
                }
            }
        }
      end

      def procedure_code_defined?
        Rails.application.secrets.red_sara_dgp_procedure_code.present?
      end
  end

  class RedSaraValidateResidenceService < RedSaraApi

    private

      def valid_code
        "0003"
      end

      def invalid_id_code
        "0229"
      end

      def generate_id
        Rails.application.secrets.red_sara_organization_id + "_R_" + Time.now.strftime("%Y%m%d") + "_" + SecureRandom.alphanumeric(5)
      end

      def get_endpoint
        if Rails.env.production?
          "https://intermediacion.redsara.es/servicios/SVD/INE.VerificacionAmbitoResidencia"
        else
          "https://intermediacionpp.redsara.es/servicios/SVD/INE.VerificacionAmbitoResidencia"
        end
      end

      def request(document_type, document_number, data)
        request_id = generate_id

        {
            "pet:Atributos": {
                "pet:IdPeticion": request_id,
                "pet:CodigoCertificado": "SVDRWS01",
                "pet:NumElementos": 1,
                "pet:TimeStamp": Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L%:z"),
            },
            "pet:Solicitudes": {
                "pet:SolicitudTransmision": {
                    "pet:DatosGenericos": {
                        "pet:Emisor": {
                            "pet:NifEmisor": "S2833002E",
                            "pet:NombreEmisor": "MINISTERIO DE HACIENDA Y AP"
                        },
                        "pet:Solicitante": {
                            "pet:IdentificadorSolicitante": Rails.application.secrets.red_sara_organization_id,
                            "pet:NombreSolicitante": Rails.application.secrets.red_sara_organization_name,
                            "pet:Procedimiento": {
                                "pet:CodProcedimiento": Rails.application.secrets.red_sara_ine_procedure_code,
                                "pet:NombreProcedimiento": Rails.application.secrets.red_sara_ine_procedure_name
                            },
                            "pet:Finalidad": "VERIFICACION RESIDENCIA EN CONSUL",
                            "pet:Consentimiento": "Si",
                        },
                        "pet:Titular": {
                            "pet:TipoDocumentacion": get_document_type(document_type),
                            "pet:Documentacion": document_number,
                        },
                        "pet:Transmision": {
                            "pet:CodigoCertificado": "SVDRWS01",
                            "pet:IdSolicitud": request_id,
                            "pet:FechaGeneracion": Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L%:z")
                        }
                    },
                    "ns1:DatosEspecificos": {
                        "ns1:Solicitud": {
                            "ns1:Espanol": dni?(document_type) ? "s" : "n",
                            "ns1:Residencia": {
                                "ns1:Provincia": data[:postal_code][0..1]
                            }
                        }
                    }
                }
            }
        }
      end

      def procedure_code_defined?
        Rails.application.secrets.red_sara_ine_procedure_code.present?
      end
  end

  class RedSaraService
    def call(document_type, document_number, data)
      identity_response = RedSaraValidateIdentityService.new.call(document_type, document_number, data)
      return Response.new if identity_response == nil
      return identity_response if !identity_response.valid?

      residence_response = RedSaraValidateResidenceService.new.call(document_type, document_number, data)
      return Response.new if residence_response == nil

      residence_response
    end

    class Response
      def valid?
        false
      end
    end
  end

  class RedSaraServiceCaller
    def call(document_type, document_number, date_of_birth, postal_code)
      if Setting["feature.red_sara_service"].present?
        data = {
            date_of_birth: date_of_birth,
            postal_code: postal_code
        }
        RedSaraService.new.call(document_type, document_number, data)
      else
        CensusCaller.new.call(document_type, document_number, date_of_birth, postal_code)
      end
    end
  end
end
