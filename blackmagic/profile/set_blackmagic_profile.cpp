#include <iostream>
#include "DeckLinkAPI.h"

int main() {
    IDeckLink* deckLink = nullptr;
    IDeckLinkIterator* deckLinkIterator = CreateDeckLinkIteratorInstance();
    IDeckLinkConfiguration* deckLinkConfiguration = nullptr;

    if (!deckLinkIterator) {
        std::cerr << "Could not create DeckLink Iterator instance." << std::endl;
        return 1;
    }

    // Get the first available DeckLink device
    if (deckLinkIterator->Next(&deckLink) != S_OK) {
        std::cerr << "No DeckLink devices found." << std::endl;
        return 1;
    }

    // Query for the configuration interface
    if (deckLink->QueryInterface(IID_IDeckLinkConfiguration, (void**)&deckLinkConfiguration) != S_OK) {
        std::cerr << "Could not query DeckLink Configuration interface." << std::endl;
        return 1;
    }

    // Set a different configuration option to test, like bypass
    HRESULT result = deckLinkConfiguration->SetInt(bmdDeckLinkConfigBypass, 1); // 1 for enabling bypass

    if (result != S_OK) {
        std::cerr << "Failed to configure DeckLink device. Error code: " << result << std::endl;
        return 1;
    }

    std::cout << "Successfully configured DeckLink device." << std::endl;

    // Clean up
    if (deckLinkConfiguration) deckLinkConfiguration->Release();
    if (deckLink) deckLink->Release();
    if (deckLinkIterator) deckLinkIterator->Release();

    return 0;
}
