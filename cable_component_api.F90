
    call cable_init(config, grid, surface_parameters, state)
    call cable_advance(dt, atmospheric_forcing, state, fluxes)
    call cable_get_surface(state, surface_fields)
    call cable_restart(mode, state)
    call cable_finalize()


