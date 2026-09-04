package com.kasperin.inventory_management.api.v1.mapper;

import com.kasperin.inventory_management.api.v1.model.FruitAndVegeDTO;
import com.kasperin.inventory_management.domain.Items.FruitAndVege;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public abstract class FruitAndVegeMapper {

        public static final FruitAndVegeMapper INSTANCE =
            Mappers.getMapper(FruitAndVegeMapper.class);

    public FruitAndVegeDTO fruitAndVegeToFruitAndVegeDTO(FruitAndVege fruitAndVege) {
        if (fruitAndVege == null) {
            return null;
        }

        FruitAndVegeDTO fruitAndVegeDTO = new FruitAndVegeDTO();
        fruitAndVegeDTO.setId(fruitAndVege.getId());
        fruitAndVegeDTO.setName(fruitAndVege.getName());
        fruitAndVegeDTO.setBarcode(fruitAndVege.getBarcode());
        fruitAndVegeDTO.setPrice(fruitAndVege.getPrice());
        fruitAndVegeDTO.setInStockQuantity(fruitAndVege.getInStockQuantity());
        return fruitAndVegeDTO;
    }

    public abstract FruitAndVege fruitAndVegeDTOtoFruitAndVege(FruitAndVegeDTO fruitAndVegeDTO);

}
