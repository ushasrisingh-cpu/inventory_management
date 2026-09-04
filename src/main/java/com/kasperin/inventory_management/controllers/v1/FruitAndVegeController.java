package com.kasperin.inventory_management.controllers.v1;

import com.kasperin.inventory_management.api.v1.model.FruitAndVegeDTO;
import com.kasperin.inventory_management.domain.Items.FruitAndVege;
import com.kasperin.inventory_management.services.itemsServices.FruitAndVegeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping(FruitAndVegeController.BASE_URL)
@RequiredArgsConstructor
public class FruitAndVegeController {

    public static final String BASE_URL = "/api/v1/fruitAndVeges";

    private final FruitAndVegeService fruitAndVegeService;

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public List<FruitAndVege> getAll(@RequestParam(value = "all", defaultValue = "") String all,
                                     @RequestParam(value = "name", defaultValue = "") String name){
            if (all.equals("all")) {
                return fruitAndVegeService.findAll();
            }else if (!name.isEmpty()) { return fruitAndVegeService.findAllByNameContaining(name);
            }
        //just get what is in stock with qty >=1 if no query
        return fruitAndVegeService.findAllInStock();
    }

    @GetMapping("/{id}")
    public ResponseEntity<FruitAndVegeDTO> getById( @PathVariable Long id){
        return new ResponseEntity<>(
                fruitAndVegeService.findById(id), HttpStatus.OK
        );
    }

    @GetMapping("/name/{name}")
    public ResponseEntity<FruitAndVegeDTO> getByName( @PathVariable String name){
        return new ResponseEntity<>(
                fruitAndVegeService.findByName(name), HttpStatus.OK
        );
    }

    @PatchMapping({"/{id}"})
    public Optional<FruitAndVege> updateById(@PathVariable Long id, @RequestBody FruitAndVege fav){
        return fruitAndVegeService.updateById(id,fav);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FruitAndVegeDTO createNewFruitAndVege(@RequestBody FruitAndVegeDTO fruitAndVegeDTO)
            throws Exception {
        return fruitAndVegeService.createNewFruitAndVege(fruitAndVegeDTO);
    }

    @DeleteMapping({"{ID}"})
    @ResponseStatus(HttpStatus.OK)
    public void deleteFruitAndVege(@PathVariable Long ID){
        fruitAndVegeService.deleteById(ID);
    }

}
