<MultiSelect value={selectedCities} onChange={(e) => setSelectedCities(e.value)} options={cities} optionLabel="name" 
    placeholder="Select Cities" maxSelectedLabels={3} className="w-full md:w-20rem" />
