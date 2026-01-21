/* ==========================================================================
   MARKUS PIZZA FLEET - CORE LOGIC
   Fixed & Optimized
   ========================================================================== */

const AppConfig = {
    // Ora rileviamo il nome della risorsa automaticamente per evitare errori 404
    resourceName: GetParentResourceName ? GetParentResourceName() : 'markus-pizzajob',
    sounds: {
        enabled: true,
        volume: 0.25,
        files: {
            click: 'click.ogg',
            hover: 'hover.ogg',
            open: 'open.ogg',
            close: 'close.ogg',
            success: 'buy.ogg'
        }
    }
};

// Application State
const State = {
    isOpen: false,
    currentView: 'selector', 
    categories: [],
    activeCategory: null,
    selectedVehicle: null
};

/* ==========================================================================
   INITIALIZATION & LISTENERS
   ========================================================================== */

$(document).ready(() => {
    $('#app-container').hide();
    setupEventListeners();
});

window.addEventListener('message', (event) => {
    const payload = event.data;

    switch (payload.action) {
        case 'openMenu':
            App.openSelector(payload.data.categories);
            break;
        case 'openFinish':
            App.openSummary(payload.data);
            break;
        case 'closeMenu':
            App.close();
            break;
    }
});

function setupEventListeners() {
    // Keyboard (ESC)
    document.onkeyup = (data) => {
        if (data.key === 'Escape' || data.key === 'Backspace') {
            if (State.currentView === 'details') {
                App.showView('selector');
                AudioManager.play('close');
                // IMPORTANTE: Reset preview quando si torna indietro
                postCallback('previewVehicle', { model: null }); 
            } else if (State.currentView === 'selector') {
                App.close();
            }
        }
    };

    $('#btn-close').click(() => App.close());
    
    $('#btn-back').click(() => {
        App.showView('selector');
        AudioManager.play('close');
        postCallback('previewVehicle', { model: null });
    });

    $(document).on('mouseenter', '.card-item, .vehicle-option, .action-btn, .nav-btn', () => {
        AudioManager.play('hover');
    });
}

/* ==========================================================================
   APP CORE FUNCTIONS
   ========================================================================== */

const App = {
    openSelector: (categories) => {
        State.categories = categories;
        State.isOpen = true;
        $('#app-container').fadeIn(300);
        App.showView('selector');
        DOM.renderCategories(categories);
        AudioManager.play('open');
    },

    openSummary: (data) => {
        State.isOpen = true;
        $('#app-container').fadeIn(300);
        DOM.renderSummary(data);
        App.showView('summary');
        AudioManager.play('open');
    },

    close: () => {
        $('#app-container').fadeOut(200);
        State.isOpen = false;
        postCallback('CloseMenu');
    },

    showView: (viewName) => {
        State.currentView = viewName;
        $('.view-panel').removeClass('active-view').addClass('hidden');
        
        if (viewName === 'selector') {
            $('#view-selector').removeClass('hidden').addClass('active-view');
        } else if (viewName === 'details' || viewName === 'summary') {
            $('#view-details').removeClass('hidden').addClass('active-view');
        }
    }
};

/* ==========================================================================
   DOM MANIPULATION
   ========================================================================== */

const DOM = {
    renderCategories: (categories) => {
        const container = $('#category-list');
        container.empty();

        categories.forEach((cat, index) => {
            const image = cat.image ? `assets/${cat.image}` : 'assets/default.png';
            const html = `
                <div class="card-item" onclick="DOM.selectCategory(${index})">
                    <div class="card-bg-text">PIZZA</div>
                    <div class="card-icon"><i class="fa-solid fa-pizza-slice"></i></div>
                    <img src="${image}" style="display:none;" onerror="this.remove()"> 
                    <div class="card-title">${cat.label}</div>
                </div>
            `;
            container.append(html);
        });
    },

    selectCategory: (index) => {
        const category = State.categories[index];
        if (!category) return;

        State.activeCategory = category;
        AudioManager.play('click');
        
        $('#vehicle-name').text('LOADING FLEET...');
        $('#vehicle-type-label').text(category.label);
        $('#btn-back').show(); 
        
        DOM.renderVehicleList(category.vehicles);
        App.showView('details');

        // Seleziona automaticamente il primo veicolo per attivare la preview
        if (category.vehicles.length > 0) {
            // Usiamo un piccolo timeout per dare tempo alla UI di aggiornarsi prima di chiamare il client
            setTimeout(() => {
                DOM.selectVehicle(category.vehicles[0].model);
            }, 50);
        }
    },

    renderVehicleList: (vehicles) => {
        const container = $('#vehicle-list');
        container.empty();
        vehicles.forEach((veh) => {
            const html = `
                <div class="vehicle-option" id="veh-${veh.model}" onclick="DOM.selectVehicle('${veh.model}')">
                    <span>${veh.label}</span>
                    <small>DEPOSIT: $${veh.price}</small>
                </div>
            `;
            container.append(html);
        });
    },

    selectVehicle: (model) => {
        const vehicle = State.activeCategory.vehicles.find(v => v.model === model);
        if (!vehicle) return;

        State.selectedVehicle = vehicle;
        AudioManager.play('click');

        $('.vehicle-option').removeClass('selected');
        $(`#veh-${model}`).addClass('selected');
        $('#vehicle-name').text(vehicle.label);

        const btnText = vehicle.price > 0 ? `START ($${vehicle.price})` : "START SHIFT";
        const btnHtml = `
            <button class="action-btn" onclick="DOM.confirmStart()">
                <span>${btnText}</span>
                <i class="fa-solid fa-key"></i>
            </button>
        `;
        $('#action-footer').html(btnHtml);

        // Debug Log per verificare se parte la chiamata
        console.log(`[JS] Requesting Preview for: ${vehicle.model}`);
        postCallback('previewVehicle', { model: vehicle.model });
    },

    confirmStart: () => {
        if (!State.selectedVehicle) return;
        AudioManager.play('success');
        
        // Disabilita bottone per evitare doppio click
        $('#action-footer button').prop('disabled', true).html('<i class="fa-solid fa-spinner fa-spin"></i> PROCESSING...');
        
        postCallback('startJob', {
            vehicleModel: State.selectedVehicle.model,
            vehicleLabel: State.selectedVehicle.label
        });

        setTimeout(() => { $('#app-container').fadeOut(200); }, 500);
    },

    renderSummary: (data) => {
        $('#btn-back').hide(); 
        $('#vehicle-name').text('SHIFT SUMMARY');
        $('#vehicle-type-label').text('COMPLETED');
        const container = $('#vehicle-list');
        container.empty();

        const statsHtml = `
            <div class="info-details" style="background: rgba(255,255,255,0.05); padding: 25px;">
                <li style="font-size: 1.2rem;">
                    <i class="fa-solid fa-box-open" style="color: var(--accent);"></i>
                    <span>DELIVERIES: <strong>${data.deliveries || 0}</strong></span>
                </li>
                <li style="font-size: 1.2rem; border-top: 1px solid rgba(255,255,255,0.1); padding-top: 15px; margin-top: 15px;">
                    <i class="fa-solid fa-money-bill-wave" style="color: var(--accent-success);"></i>
                    <span>EARNINGS: <strong style="color: #fff; font-size: 1.4rem;">$${(data.total || 0).toLocaleString()}</strong></span>
                </li>
            </div>
        `;
        container.append(statsHtml);

        const btnHtml = `
            <button class="action-btn" onclick="DOM.confirmFinish()">
                <span>COLLECT PAYCHECK</span>
                <i class="fa-solid fa-signature"></i>
            </button>
        `;
        $('#action-footer').html(btnHtml);
    },

    confirmFinish: () => {
        AudioManager.play('success');
        postCallback('confirmFinish');
        $('#app-container').fadeOut(200);
    }
};

/* ==========================================================================
   UTILITIES
   ========================================================================== */

const AudioManager = {
    play: (soundName) => {
        if (!AppConfig.sounds.enabled) return;
        const file = AppConfig.sounds.files[soundName];
        if (!file) return;
        const audio = new Audio(`./sounds/${file}`);
        audio.volume = AppConfig.sounds.volume;
        audio.play().catch(() => {}); 
    }
};

function postCallback(name, data = {}) {
    // Tentativo di chiamata con gestione errore
    try {
        $.post(`https://${AppConfig.resourceName}/${name}`, JSON.stringify(data));
    } catch (e) {
        console.error("NUI POST Error:", e);
    }
}