from sageImport import sage_import
sage_import('constants', fromlist=['BASE_FIELD'])
sage_import('affinePoint', fromlist=['AffinePoint'])
sage_import('projectivePoint', fromlist=['ProjectivePoint'])

class Converter():
    def affineToProjective(point: AffinePoint):
        if point.notInfty:
            return ProjectivePoint(point.x, point.y, 1, name=point.name)
        else:
            return ProjectivePoint(0, 1, 0, name=point.name)
    
    def projectiveToAffine(point: ProjectivePoint):
        if point.Z != 0:
            return AffinePoint(point.X/point.Z, point.Y/point.Z, 1, name=point.name)
        else:
            return AffinePoint(0, 0, 1, name=point.name)
