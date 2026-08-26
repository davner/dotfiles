// use the CSS style directly
<Dropdown dropdownIcon="fa-light fa-chevron-down" />

// use the pre-built icons
<Dropdown dropdownIcon={(options) => <FontAwesomeIcon icon={["fal", "chevron-down"]}  {...options.iconProps} /> } />
