package com.kasperin.inventory_management.controllers.v1;

import com.kasperin.inventory_management.services.itemsServices.ItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping(ItemController.BASE_URL)
public class ItemController {

    public static final String BASE_URL = "/api/v1/items";

    private final ItemService itemService;

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public List<Object> getAllItems(@RequestParam(value = "all", defaultValue = "") String all){
        if (all.equals("all")){ return itemService.findAll();
        }
        //Else by default just get what is in stock with qty >=1
        return itemService.findAllInStock();
    }

}
