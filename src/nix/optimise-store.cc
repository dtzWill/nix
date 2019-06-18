#include "command.hh"
#include "shared.hh"
#include "store-api.hh"

#include <atomic>

using namespace nix;

struct CmdOptimiseStore : StoreCommand
{
    std::string description() override
    {
        return "replace identical files in the store by hard links";
    }

    Examples examples() override
    {
        return {
            Example{
                "To optimise the Nix store:",
                "nix optimise-store"
            },
        };
    }

    void run(ref<Store> store) override
    {
        store->optimiseStore();
    }
};

static auto r1 = registerCommand<CmdOptimiseStore>("optimise-store");
static auto r2 = registerCommand<CmdOptimiseStore>("optimize-store");
