<MultiSelect value={selectedCities} options={groupedCities} onChange={(e) => setSelectedCities(e.value)} optionLabel="label" 
    optionGroupLabel="label" optionGroupChildren="items" optionGroupTemplate={groupedItemTemplate}
    placeholder="Select Cities" display="chip" className="w-full md:w-20rem" />
