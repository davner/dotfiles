<FloatLabel>
    <MultiSelect value={selectedCities} onChange={(e) => setSelectedCities(e.value)} options={cities} optionLabel="name" maxSelectedLabels={3} className="w-full" />
    <label htmlFor="ms-cities">MultiSelect</label>
</FloatLabel>
