package com.kasperin.inventory_management.domain.Items;

import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import jakarta.persistence.Entity;

@EqualsAndHashCode(callSuper = true)
@Data
@Entity
@NoArgsConstructor
public class OrderedFruitAndVegeItem extends OrderedItem{
    public OrderedFruitAndVegeItem(FruitAndVege fruitAndVege) {
        super.setName(fruitAndVege.getName());
        super.setBarcode(fruitAndVege.getBarcode());
        super.setQuantity(fruitAndVege.getInStockQuantity());
        super.setPrice(fruitAndVege.getPrice());
    }
}
