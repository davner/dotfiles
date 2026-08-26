<FloatLabel>
    <Dropdown inputId="dd-city" value={selectedCity} onChange={(e) => setSelectedCity(e.value)} options={cities} optionLabel="name" className="w-full" />
    <label htmlFor="dd-city">Select a City</label>
</FloatLabel>
