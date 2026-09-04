package com.kasperin.inventory_management.controllers.v1;

import com.kasperin.inventory_management.domain.Items.Stationary;
import com.kasperin.inventory_management.services.itemsServices.StationaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping(StationaryController.BASE_URL)
@RequiredArgsConstructor
public class StationaryController {

    public static final String BASE_URL = "/api/v1/stationary";

    private final StationaryService stationaryService;


    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public List<Stationary> getAll(@RequestParam(value = "all", defaultValue = "") String all,
                                   @RequestParam(value = "name", defaultValue = "") String name){
        if (all.equals("all")){ return stationaryService.findAll();
        }else if (!name.isEmpty()) { return stationaryService.findAllByNameContaining(name);
        }
        //just get what is in stock with qty >=1 if no query
        return stationaryService.findAllInStock();
    }

    @GetMapping({"/{id}"})
    @ResponseStatus(HttpStatus.OK)
    public Optional<Stationary> getById(@PathVariable Long id) {
            return stationaryService.findById(id);
    }

    @GetMapping("/name/{name}")
    @ResponseStatus(HttpStatus.OK)
    public Stationary getByName(@PathVariable("name") String name){
        return stationaryService.findByName(name);
    }

    @PatchMapping({"/{id}"})
    public Optional<Stationary> updateById(@PathVariable Long id, @RequestBody Stationary stationary){
        return stationaryService.updateById(id,stationary);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Stationary createNewStationary(@RequestBody Stationary stationary) throws Exception {
        return stationaryService.save(stationary);
        //        if(stationaryService.existsById(stationary)){
//            return ResponseEntity.badRequest()
//                    .body("Year cannot be in the future");
//
//        }
//        return ResponseEntity.stationaryService.save(stationary)>;
    }

    @DeleteMapping({"{id}"})
    @ResponseStatus(HttpStatus.OK)
    public void deleteById(@PathVariable Long id) {
        stationaryService.deleteById(id);
    }

}
