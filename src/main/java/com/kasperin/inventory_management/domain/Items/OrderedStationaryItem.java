package com.kasperin.inventory_management.domain.Items;

import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import jakarta.persistence.Entity;

@EqualsAndHashCode(callSuper = true)
@SuppressWarnings("JpaDataSourceORMInspection")
@Data
@Entity
@NoArgsConstructor
public class OrderedStationaryItem extends OrderedItem{
    public OrderedStationaryItem(Stationary stationary){
        super.setName(stationary.getName());
        super.setBarcode(stationary.getBarcode());
        super.setQuantity(stationary.getInStockQuantity());
        super.setPrice(stationary.getPrice());
    }
}
