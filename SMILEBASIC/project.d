module otya.smilebasic.project;
import std.path;
import std.file;
import std.string;
import std.traits;
import std.conv;
import std.uni;
import std.typecons;
class Projects
{
    wstring rootPath;
    wstring projectPath;
    string projectPathU8;
    this(wstring root)
    {
        rootPath = root;
        projectPath = buildPath(root, "PROJECTS"w);
        projectPathU8 = projectPath.to!string;
        if(exists(projectPathU8))
        {
            if(isFile(projectPathU8))
            {
                throw new Exception("PROJECTS is file");
            }
        }
        else
        {
            mkdir(projectPathU8);
        }
        createProjectInternal("[DEFAULT]");
        createProjectInternal("SYS");
    }
    bool isValidProjectName(C)(C[] filename) if(isSomeChar!(C))
    {
        if(filename.length > 14)
        {
            return false;
        }
        foreach(c; filename)
        {
            if(!((c >= 'A' && c<= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '-'))
            {
                return false;
            }
        }
        return true;
    }
    bool isValidFileName(C)(C[] filename) if(isSomeChar!(C))
    {
        if(filename.length > 12)
        {
            return false;
        }
        foreach(c; filename)
        {
            if(!((c >= 'A' && c<= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '.' || c == '_' || c == '-' || c == '@'))
            {
                return false;
            }
        }
        return true;
    }
    private void createProjectInternal(wstring name)
    {
        auto path = buildPath(projectPath, name.toUpper).to!string;
        if(!exists(path))
        {
            mkdir(path);
        }
        auto txt = buildPath(path, "TXT").to!string;
        if(!exists(txt))
        {
            mkdir(txt);
        }
        auto dat = buildPath(path, "DAT").to!string;
        if(!exists(dat))
        {
            mkdir(dat);
        }
    }
    static Tuple!(wstring, wstring, wstring) splitResourceName(wstring name)
    {
        auto ind = name.indexOf(":");
        wstring type, project;
        if(ind != -1)
        {
            type = name[0..ind];
            name = name[ind + 1..$];
        }
        ptrdiff_t sep = name.indexOf("/");
        if(sep != -1)
        {
            project = name[0..sep];
            name = name[sep + 1..$];
        }
        return tuple(type, project, name);
    }
    bool loadFile(wstring project, wstring type, wstring name, out wstring contents)
    {
        contents = "";
        if(!isValidProjectName(project))
        {
            return false;
        }
        if(project == "") project = "[DEFAULT]";
        if(type != "TXT" && type != "DAT")
        {
            return false;
        }
        if(!isValidFileName(name))
        {
            return false;
        }
        auto path = buildPath(projectPath, project, type, name).to!string;
        contents = readText(path).to!wstring;
        return true;
    }
}
