package com.kasperin.inventory_management.controllers.v1;

import com.kasperin.inventory_management.domain.enums.FoodType;
import com.kasperin.inventory_management.domain.Items.ProcessedFood;
import com.kasperin.inventory_management.services.itemsServices.ProcessedFoodService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping(ProcessedFoodController.BASE_URL)
@RequiredArgsConstructor
public class ProcessedFoodController {

    public static final String BASE_URL = "/api/v1/processedFoods";

    private final ProcessedFoodService processedFoodService;

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public List<ProcessedFood> getAll(@RequestParam(value = "type", defaultValue = "") Optional<FoodType> foodType,
                                      @RequestParam(value = "all", defaultValue = "") String all,
                                      @RequestParam(value = "name", defaultValue = "") String name) {
        if (foodType.isPresent()) return processedFoodService.findByType(foodType.get());
        if (all.equals("all"))    return processedFoodService.findAll();
        if (!name.isEmpty())      return processedFoodService.findAllByNameContaining(name);
        //else return everything
                                  return processedFoodService.findAllInStock();
    }

    @GetMapping(value = "/name/{name}", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public ProcessedFood getByName(@PathVariable String name) {
        return processedFoodService.findByName(name);
    }

    @GetMapping({"/{id}"})
    @ResponseStatus(HttpStatus.OK)
    public Optional<ProcessedFood> getById(@PathVariable Long id) {
        return processedFoodService.findById(id);
    }

    @PatchMapping({"/{id}"})
    public Optional<ProcessedFood> updateById(@PathVariable Long id, @RequestBody ProcessedFood processedFood){
        return processedFoodService.updateById(id,processedFood);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ProcessedFood createNewProcessedFood(@RequestBody ProcessedFood processedFood) throws Exception {
        return processedFoodService.save(processedFood);
    }

    @DeleteMapping({"{ID}"})
    @ResponseStatus(HttpStatus.OK)
    public void deleteById(@PathVariable Long ID) {
        processedFoodService.deleteById(ID);
    }
}
