#pragma once

#include "crypto.hh"
#include "store-api.hh"

#include "pool.hh"

#include <atomic>

namespace nix {

struct NarInfo;

class BinaryCacheStore : public Store
{
public:

    const Setting<std::string> compression{this, "xz", "compression", "NAR compression method ('xz', 'bzip2', or 'none')"};
    const Setting<bool> writeNARListing{this, false, "write-nar-listing", "whether to write a JSON file listing the files in each NAR"};
    const Setting<bool> writeDebugInfo{this, false, "index-debug-info", "whether to index DWARF debug info files by build ID"};
    const Setting<Path> secretKeyFile{this, "", "secret-key", "path to secret key used to sign the binary cache"};
    const Setting<Path> localNarCache{this, "", "local-nar-cache", "path to a local cache of NARs"};
    const Setting<bool> parallelCompression{this, false, "parallel-compression",
        "enable multi-threading compression for NARs, available for xz only currently"};
    const Setting<int> compressionLevel{this, -1, "compression-level",
        "specify 'preset level' of compression to be used with NARs: "
        "meaning and accepted range of values depends on compression method selected, "
        "other than -1 which we reserve to indicate Nix defaults should be used"};

private:

    std::unique_ptr<SecretKey> secretKey;

protected:

    BinaryCacheStore(const Params & params);

public:

    virtual bool fileExists(const std::string & path) = 0;

    virtual void upsertFile(const std::string & path,
        const std::string & data,
        const std::string & mimeType) = 0;

    /* Note: subclasses must implement at least one of the two
       following getFile() methods. */

    /* Dump the contents of the specified file to a sink. */
    virtual void getFile(const std::string & path, Sink & sink);

    /* Fetch the specified file and call the specified callback with
       the result. A subclass may implement this asynchronously. */
    virtual void getFile(const std::string & path,
        Callback<std::shared_ptr<std::string>> callback) noexcept;

    std::shared_ptr<std::string> getFile(const std::string & path);

public:

    virtual void init();

private:

    std::string narMagic;

    std::string narInfoFileFor(const Path & storePath);

    void writeNarInfo(ref<NarInfo> narInfo);

public:

    bool isValidPathUncached(const Path & path) override;

    void queryPathInfoUncached(const Path & path,
        Callback<std::shared_ptr<const ValidPathInfo>> callback) noexcept override;

    Path queryPathFromHashPart(const string & hashPart) override
    { unsupported("queryPathFromHashPart"); }

    void addToStore(const ValidPathInfo & info, const ref<std::string> & nar,
        RepairFlag repair, CheckSigsFlag checkSigs,
        std::shared_ptr<FSAccessor> accessor) override;

    Path addToStore(const string & name, const Path & srcPath,
        bool recursive, HashType hashAlgo,
        PathFilter & filter, RepairFlag repair) override;

    Path addTextToStore(const string & name, const string & s,
        const PathSet & references, RepairFlag repair) override;

    void narFromPath(const Path & path, Sink & sink) override;

    BuildResult buildDerivation(const Path & drvPath, const BasicDerivation & drv,
        BuildMode buildMode) override
    { unsupported("buildDerivation"); }

    void ensurePath(const Path & path) override
    { unsupported("ensurePath"); }

    ref<FSAccessor> getFSAccessor() override;

    void addSignatures(const Path & storePath, const StringSet & sigs) override;

    std::shared_ptr<std::string> getBuildLog(const Path & path) override;

};

MakeError(NoSuchBinaryCacheFile, Error);

}
