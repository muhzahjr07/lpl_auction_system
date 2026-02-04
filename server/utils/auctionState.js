const initialShowState = {
    activePlayerId: null,
    currentPrice: 0,
    startTime: null,
    lastBidder: null,
    lastBidderId: null,
    lastBidderTeamLogo: null
};

let currentState = { ...initialShowState };

module.exports = {
    get: () => currentState,
    set: (newState) => {
        currentState = { ...currentState, ...newState };
    },
    reset: () => {
        currentState = { ...initialShowState };
    }
};
