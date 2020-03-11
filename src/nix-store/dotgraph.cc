#include "dotgraph.hh"
#include "util.hh"
#include "store-api.hh"

#include <iostream>


using std::cout;

namespace nix {


static string dotQuote(const string & s)
{
    return "\"" + s + "\"";
}


static string nextColour()
{
    static int n = 0;
    static string colours[] =
        { "black", "red", "green", "blue"
        , "magenta", "burlywood" };
    return colours[n++ % (sizeof(colours) / sizeof(string))];
}


static string makeEdge(const string & src, const string & dst)
{
    format f = format("%1% -> %2% [color = %3%];\n")
        % dotQuote(src) % dotQuote(dst) % dotQuote(nextColour());
    return f.str();
}


static string makeNode(const string & id, const string & label,
    const string & colour)
{
    format f = format("%1% [label = %2%, shape = box, "
        "style = filled, fillcolor = %3%];\n")
        % dotQuote(id) % dotQuote(label) % dotQuote(colour);
    return f.str();
}


static string symbolicName(const string & path)
{
    string p = baseNameOf(path);
    return string(p, p.find('-') + 1);
}


void printDotGraph(ref<Store> store, const PathSet & roots)
{
    PathSet workList(roots);
    PathSet doneSet;

    cout << "digraph G {\n";

    while (!workList.empty()) {
        Path path = *(workList.begin());
        workList.erase(path);

        if (!doneSet.insert(path).second) continue;

        cout << makeNode(path, symbolicName(path), "#ff0000");

        for (auto & p : store->queryPathInfo(path)->references) {
            if (p != path) {
                workList.insert(p);
                cout << makeEdge(p, path);
            }
        }

    }

    cout << "}\n";
}


}
