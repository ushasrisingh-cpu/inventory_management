package com.kasperin.inventory_management.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI inventoryManagementOpenAPI() {
    return new OpenAPI()
        .info(new Info()
            .title("Inventory Management System")
            .description("This is an inventory management system that exercises RESTful API")
            .version("1.0")
            .termsOfService("Terms of Service: ")
            .contact(new Contact()
                .name("Vaughn Nze")
                .url("http://10.1.3.232:8080/swagger-ui.html#/")
                .email("vaughnnze@gmail.com"))
            .license(new License()
                .name("MIT License")
                .url("https://opensource.org/licenses/MIT")));
    }

}
