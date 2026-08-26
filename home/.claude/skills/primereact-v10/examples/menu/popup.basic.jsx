<Toast ref={toast}></Toast>
<Menu model={items} popup ref={menuLeft} id="popup_menu_left" />
<Button label="Show Left" icon="pi pi-align-left" className="mr-2" onClick={(event) => menuLeft.current.toggle(event)} aria-controls="popup_menu_left" aria-haspopup />
<Menu model={items} popup ref={menuRight} id="popup_menu_right" popupAlignment="right" />
<Button label="Show Right" icon="pi pi-align-right" className="mr-2" onClick={(event) => menuRight.current.toggle(event)} aria-controls="popup_menu_right" aria-haspopup />
