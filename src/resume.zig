const std = @import("std");
const json: type = std.json;

pub const Experience = struct { company: []const u8, role: []const u8, duration: []const u8, description: []const u8 };

pub const Resume: type = struct { name: []const u8, email: []const u8, skills: [][]const u8, experience: []Experience };

pub fn loadResume(allocator: *std.mem.Allocator, filePath: []const u8) Resume {
    const resumeFile = try std.fs.cwd().openFile(filePath, .{});
    defer resumeFile.close();

    const fileSize = try resumeFile.getEndPos();
    var fileBuffer = try allocator.alloc(u8, fileSize);
    defer allocator.free(fileBuffer);

    try resumeFile.readAll(fileBuffer);

    const resumeJson = try json.parse(fileBuffer, allocator);
    defer json.Value.dump(resumeJson);

    return try parseResumeFromJson(resumeJson);
}

fn parseResumeFromJson(json_resume: json.Value) !Resume {
    const obj = json_resume.object;

    const name: []const u8 = try obj.get("name").String;
    const email: []const u8 = try obj.get("email").String;
    const skills: [][]const u8 = try obj.get("skills").Array;

    const experience_json = try obj.get("experience").Array;
    var experience: []Experience = try std.heap.page_allocator.alloc(Experience, experience_json.len);

    for (experience_json.items, 0..) |exp, i| {
        experience[i] = try parseExperienceFromJson(exp);
    }

    return Resume{ .name = name, .email = email, .skills = skills, .experience = experience };
}

fn parseExperienceFromJson(json_experience: json.Value) !Experience {
    const obj = json_experience.object;

    return Experience{ .company = try obj.get("company").String, .role = try obj.get("role").String, .duration = try obj.get("duration").String, .description = try obj.get("description").String };
}
